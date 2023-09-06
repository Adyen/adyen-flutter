import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/models/drop_in_outcome.dart';
import 'package:adyen_checkout/src/models/payment_flow.dart';
import 'package:adyen_checkout/src/models/payment_type.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_platform_interface.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_result_api.dart';

class AdyenCheckout implements AdyenCheckoutInterface {
  AdyenCheckout() {
    _setupResultApi();
  }

  final AdyenCheckoutResultApi _resultApi = AdyenCheckoutResultApi();

  @override
  Future<String> getPlatformVersion() =>
      AdyenCheckoutPlatformInterface.instance.getPlatformVersion();

  @override
  Future<String> getReturnUrl() =>
      AdyenCheckoutPlatformInterface.instance.getReturnUrl();

  @override
  Future<PaymentResult> startPayment({required PaymentFlow paymentFlow}) async {
    switch (paymentFlow.paymentType) {
      case PaymentType.dropInSessions:
        return await _startDropInSessionsPayment(
          paymentFlow.session!,
          paymentFlow.dropInConfiguration,
        );
      case PaymentType.dropInAdvancedFlow:
        return await _startDropInAdvancedFlowPayment(
          paymentFlow.paymentMethodsResponse!,
          paymentFlow.dropInConfiguration,
          (paymentComponentJson) =>
              paymentFlow.postPayments!(paymentComponentJson),
          (additionalDetailsJson) =>
              paymentFlow.postPaymentsDetails!(additionalDetailsJson),
        );
    }
  }

  Future<PaymentResult> _startDropInSessionsPayment(
    Session session,
    DropInConfiguration dropInConfiguration,
  ) async {
    _resultApi.dropInSessionResultStream = StreamController<PaymentResult>();
    AdyenCheckoutPlatformInterface.instance.startDropInSessionPayment(
      session,
      dropInConfiguration,
    );
    final sessionDropInResultModel =
        await _resultApi.dropInSessionResultStream.stream.first;
    await _resultApi.dropInSessionResultStream.close();
    return sessionDropInResultModel;
  }

  Future<PaymentResult> _startDropInAdvancedFlowPayment(
    String paymentMethodsResponse,
    DropInConfiguration dropInConfiguration,
    Future<DropInOutcome> Function(String paymentComponentJson) postPayments,
    Future<DropInOutcome> Function(String additionalDetailsJson)
        postPaymentsDetails,
  ) async {
    final dropInAdvancedFlowCompleter = Completer<PaymentResult>();
    AdyenCheckoutPlatformInterface.instance.startDropInAdvancedFlowPayment(
      paymentMethodsResponse,
      dropInConfiguration,
    );

    _resultApi.dropInAdvancedFlowPlatformCommunicationStream =
        StreamController<PlatformCommunicationModel>.broadcast();
    _resultApi.dropInAdvancedFlowPlatformCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      switch (event.type) {
        case PlatformCommunicationType.paymentComponent:
          await _handlePaymentComponent(event, postPayments);
        case PlatformCommunicationType.additionalDetails:
          await _handleAdditionalDetails(event, postPaymentsDetails);
        case PlatformCommunicationType.result:
          _handleResult(dropInAdvancedFlowCompleter, event);
      }
    });

    return dropInAdvancedFlowCompleter.future.then((value) {
      _resultApi.dropInAdvancedFlowPlatformCommunicationStream.close();
      return value;
    });
  }

  void _handleResult(
    Completer<PaymentResult> dropInAdvancedFlowCompleter,
    PlatformCommunicationModel event,
  ) {
    dropInAdvancedFlowCompleter.complete(event.paymentResult);
  }

  Future<void> _handleAdditionalDetails(
    PlatformCommunicationModel event,
    Future<DropInOutcome> Function(String additionalDetails)
        postPaymentsDetails,
  ) async {
    if (event.data != null) {
      final DropInOutcome paymentsDetailsResult =
          await postPaymentsDetails(event.data!);
      DropInResult dropInResult = mapToDropInResult(paymentsDetailsResult);
      AdyenCheckoutPlatformInterface.instance
          .onPaymentsDetailsResult(dropInResult);
    }
  }

  Future<void> _handlePaymentComponent(
    PlatformCommunicationModel event,
    Future<DropInOutcome> Function(String paymentComponentJson) postPayments,
  ) async {
    if (event.data != null) {
      final DropInOutcome paymentsResult = await postPayments(event.data!);
      DropInResult dropInResult = mapToDropInResult(paymentsResult);
      AdyenCheckoutPlatformInterface.instance.onPaymentsResult(dropInResult);
    }
  }

  DropInResult mapToDropInResult(DropInOutcome dropInOutcome) {
    return switch (dropInOutcome) {
      Finished() => DropInResult(
          dropInResultType: DropInResultType.finished,
          result: dropInOutcome.resultCode,
        ),
      Action() => DropInResult(
          dropInResultType: DropInResultType.action,
          actionResponse: dropInOutcome.actionResponse,
        ),
      Error() => DropInResult(
          dropInResultType: DropInResultType.error,
          error: DropInError(
            errorMessage: dropInOutcome.errorMessage,
            reason: dropInOutcome.reason,
            dismissDropIn: dropInOutcome.dismissDropIn,
          ),
        ),
    };
  }

  void _setupResultApi() => CheckoutFlutterApi.setup(_resultApi);
}
