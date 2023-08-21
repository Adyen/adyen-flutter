import 'dart:async';
import 'dart:convert';

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

  Future<SessionDropInResultModel> startDropInAdvancedFlowPayment(
    String paymentMethodsResponse,
    DropInConfigurationModel dropInConfiguration,
    Future<Map<String, dynamic>> Function(String paymentComponentJson)
        postPayments,
    Future<Map<String, dynamic>> Function(String additionalDetails)
        postPaymentsDetails,
  ) async {
    final completer = Completer<SessionDropInResultModel>();
    launchAdvancedFlow(
      paymentMethodsResponse,
      dropInConfiguration,
      postPayments,
      postPaymentsDetails,
      completer,
    );
    return completer.future;
  }

  Future<void> launchAdvancedFlow(
    String paymentMethodsResponse,
    DropInConfigurationModel dropInConfiguration,
    Future<Map<String, dynamic>> Function(String paymentComponentJson)
        postPayments,
    Future<Map<String, dynamic>> Function(String additionalDetails)
        postPaymentsDetails,
    Completer<dynamic> completer,
  ) async {
    _adyenCheckoutResultApi.dropInAdvancedFlowResultStream =
        StreamController<SessionDropInResultModel>();
    _adyenCheckoutResultApi.dropInAdvancedFlowResultStream.stream.first
        .then((value) {
      completer.complete(value);
      _adyenCheckoutResultApi.dropInAdvancedFlowResultStream.close();
    });

    final paymentComponent =
        await AdyenCheckoutInterface.instance.startDropInAdvancedFlowPayment(
      paymentMethodsResponse,
      dropInConfiguration,
    );

    final paymentsResult = await postPayments(paymentComponent);
    final additionalDetails = await onPaymentsResult(paymentsResult);
    if (additionalDetails != null) {
      await onPaymentsDetailsResult(json.decode(additionalDetails));
    }
  }

  Future<String> getReturnUrl() async {
    return await AdyenCheckoutInterface.instance.getReturnUrl();
  }

  Future<String?> onPaymentsResult(Map<String, Object?> paymentsResult) async {
    return await AdyenCheckoutInterface.instance
        .onPaymentsResult(paymentsResult);
  }

  Future<void> onPaymentsDetailsResult(
      Map<String, Object?> paymentsDetailsResult) async {
    await AdyenCheckoutInterface.instance
        .onPaymentsDetailsResult(paymentsDetailsResult);
  }

  void _setupCheckoutResultApi() =>
      CheckoutResultFlutterInterface.setup(_adyenCheckoutResultApi);
}
