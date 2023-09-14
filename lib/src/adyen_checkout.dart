import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
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
    switch (paymentFlow) {
      case DropInSession():
        return await _startDropInSessionsPayment(paymentFlow);
      case DropInAdvancedFlow():
        return await _startDropInAdvancedFlowPayment(paymentFlow);
    }
  }

  Future<PaymentResult> _startDropInSessionsPayment(
      DropInSession dropInSession) async {
    _resultApi.dropInSessionResultStream = StreamController<PaymentResult>();
    DropInConfigurationDTO dropInConfiguration = DropInConfigurationDTO(
      environment: dropInSession.dropInConfiguration.environment,
      clientKey: dropInSession.dropInConfiguration.clientKey,
      countryCode: dropInSession.dropInConfiguration.countryCode,
      amount: dropInSession.dropInConfiguration.amount,
      cardsConfiguration: dropInSession.dropInConfiguration.cardsConfiguration,
    );
    AdyenCheckoutPlatformInterface.instance.startDropInSessionPayment(
      dropInSession.session,
      dropInConfiguration,
    );
    final sessionDropInResultModel =
        await _resultApi.dropInSessionResultStream.stream.first;
    await _resultApi.dropInSessionResultStream.close();
    return sessionDropInResultModel;
  }

  Future<PaymentResult> _startDropInAdvancedFlowPayment(
      DropInAdvancedFlow dropInAdvancedFlow) async {
    final dropInAdvancedFlowCompleter = Completer<PaymentResult>();
    DropInConfigurationDTO dropInConfiguration = DropInConfigurationDTO(
      environment: dropInAdvancedFlow.dropInConfiguration.environment,
      clientKey: dropInAdvancedFlow.dropInConfiguration.clientKey,
      countryCode: dropInAdvancedFlow.dropInConfiguration.countryCode,
      amount: dropInAdvancedFlow.dropInConfiguration.amount,
      cardsConfiguration:
          dropInAdvancedFlow.dropInConfiguration.cardsConfiguration,
    );
    AdyenCheckoutPlatformInterface.instance.startDropInAdvancedFlowPayment(
      dropInAdvancedFlow.paymentMethodsResponse,
      dropInConfiguration,
    );

    _resultApi.dropInAdvancedFlowPlatformCommunicationStream =
        StreamController<PlatformCommunicationModel>.broadcast();
    _resultApi.dropInAdvancedFlowPlatformCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      switch (event.type) {
        case PlatformCommunicationType.paymentComponent:
          await _handlePaymentComponent(event, dropInAdvancedFlow.postPayments);
        case PlatformCommunicationType.additionalDetails:
          await _handleAdditionalDetails(
              event, dropInAdvancedFlow.postPaymentsDetails);
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
