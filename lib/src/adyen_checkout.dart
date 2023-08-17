import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/adyen_checkout_result_api.dart';

class AdyenCheckout {
  AdyenCheckout() {
    _setupCheckoutResultApi();
  }

  final AdyenCheckoutResultApi _adyenCheckoutResultApi =
      AdyenCheckoutResultApi();

  Future<String> getPlatformVersion() {
    return AdyenCheckoutInterface.instance.getPlatformVersion();
  }

  Future<SessionDropInResultModel> startDropInSessionsPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) async {
    _adyenCheckoutResultApi.sessionDropInResultStream =
        StreamController<SessionDropInResultModel>();

    AdyenCheckoutInterface.instance.startPayment(
      sessionModel,
      dropInConfiguration,
    );

    final sessionDropInResultModel =
        await _adyenCheckoutResultApi.sessionDropInResultStream.stream.first;
    await _adyenCheckoutResultApi.sessionDropInResultStream.close();
    return sessionDropInResultModel;
  }

  Future<String> startDropInAdvancedFlowPayment(
    String paymentMethodsResponse,
    DropInConfigurationModel dropInConfiguration,
  ) async {
    _adyenCheckoutResultApi.dropInAdvancedFlowPaymentComponentStream =
        StreamController<String>();

    AdyenCheckoutInterface.instance.startDropInAdvancedFlowPayment(
      paymentMethodsResponse,
      dropInConfiguration,
    );

    final result = await _adyenCheckoutResultApi
        .dropInAdvancedFlowPaymentComponentStream.stream.first;
    await _adyenCheckoutResultApi.dropInAdvancedFlowPaymentComponentStream
        .close();
    return result;
  }

  Future<String> getReturnUrl() {
    return AdyenCheckoutInterface.instance.getReturnUrl();
  }

  Future<void> onPaymentsResult(Map<String, Object?> paymentsResult) {
    return AdyenCheckoutInterface.instance.onPaymentsResult(paymentsResult);
  }

  void _setupCheckoutResultApi() =>
      CheckoutResultFlutterInterface.setup(_adyenCheckoutResultApi);
}
