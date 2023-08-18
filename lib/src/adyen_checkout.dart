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
    final paymentComponent =
        await AdyenCheckoutInterface.instance.startDropInAdvancedFlowPayment(
      paymentMethodsResponse,
      dropInConfiguration,
    );

    return paymentComponent;
  }

  Future<String> getReturnUrl() async {
    return AdyenCheckoutInterface.instance.getReturnUrl();
  }

  Future<String> onPaymentsResult(Map<String, Object?> paymentsResult) async {
    final result =
        await AdyenCheckoutInterface.instance.onPaymentsResult(paymentsResult);

    return result ?? "ERROR";
  }

  Future<void> onPaymentsDetailsResult(
      Map<String, Object?> paymentsDetailsResult) async {
    _adyenCheckoutResultApi.dropInAdvancedFlowResultStream =
        StreamController<SessionDropInResultModel>();

    AdyenCheckoutInterface.instance
        .onPaymentsDetailsResult(paymentsDetailsResult);

    final sessionDropInResultModel =
    await _adyenCheckoutResultApi.sessionDropInResultStream.stream.first;
    await _adyenCheckoutResultApi.sessionDropInResultStream.close();
  }

  void _setupCheckoutResultApi() =>
      CheckoutResultFlutterInterface.setup(_adyenCheckoutResultApi);
}
