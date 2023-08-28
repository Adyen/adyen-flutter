import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
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
  Future<DropInResultModel> startPayment(
      {required PaymentFlow paymentFlow}) async {
    switch (paymentFlow.paymentType) {
      case PaymentType.dropInSessions:
        return await _startDropInSessionsPayment(
          paymentFlow.sessionModel!,
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

  Future<DropInResultModel> _startDropInSessionsPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) async {
    _resultApi.dropInSessionResultStream =
        StreamController<DropInResultModel>();
    AdyenCheckoutPlatformInterface.instance.startPayment(
      sessionModel,
      dropInConfiguration,
    );
    final sessionDropInResultModel =
        await _resultApi.dropInSessionResultStream.stream.first;
    await _resultApi.dropInSessionResultStream.close();
    return sessionDropInResultModel;
  }

  Future<DropInResultModel> _startDropInAdvancedFlowPayment(
    String paymentMethodsResponse,
    DropInConfigurationModel dropInConfiguration,
    Future<Map<String, dynamic>> Function(String paymentComponentJson)
        postPayments,
    Future<Map<String, dynamic>> Function(String additionalDetails)
        postPaymentsDetails,
  ) async {
    final dropInAdvancedFlowCompleter = Completer<DropInResultModel>();
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

  void _handleResult(Completer<DropInResultModel> dropInAdvancedFlowCompleter,
      PlatformCommunicationModel event) {
    dropInAdvancedFlowCompleter.complete(event.result);
  }

  Future<void> _handleAdditionalDetails(
    PlatformCommunicationModel event,
    Future<Map<String, dynamic>> Function(String additionalDetails)
        postPaymentsDetails,
  ) async {
    if (event.data != null) {
      final Map<String, dynamic> paymentsDetailsResult =
          await postPaymentsDetails(event.data!);
      AdyenCheckoutPlatformInterface.instance
          .onPaymentsDetailsResult(paymentsDetailsResult);
    }
  }

  Future<void> _handlePaymentComponent(
    PlatformCommunicationModel event,
    Future<Map<String, dynamic>> Function(String paymentComponentJson)
        postPayments,
  ) async {
    if (event.data != null) {
      final Map<String, dynamic> paymentsResult =
          await postPayments(event.data!);
      AdyenCheckoutPlatformInterface.instance.onPaymentsResult(paymentsResult);
    }
  }

  void _setupResultApi() => CheckoutFlutterApi.setup(_resultApi);
}
