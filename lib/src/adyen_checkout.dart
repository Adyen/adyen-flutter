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

  Future<DropInResultModel> startDropInSessionsPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) async {
    _adyenCheckoutResultApi.sessionDropInResultStream =
        StreamController<DropInResultModel>();

    AdyenCheckoutInterface.instance.startPayment(
      sessionModel,
      dropInConfiguration,
    );

    final sessionDropInResultModel =
        await _adyenCheckoutResultApi.sessionDropInResultStream.stream.first;
    await _adyenCheckoutResultApi.sessionDropInResultStream.close();
    return sessionDropInResultModel;
  }

  Future<DropInResultModel> startDropInAdvancedFlowPayment(
    String paymentMethodsResponse,
    DropInConfigurationModel dropInConfiguration,
    Future<Map<String, dynamic>> Function(String paymentComponentJson)
        postPayments,
    Future<Map<String, dynamic>> Function(String additionalDetails)
        postPaymentsDetails,
  ) async {
    final completer = Completer<DropInResultModel>();
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
    AdyenCheckoutInterface.instance.startDropInAdvancedFlowPayment(
      paymentMethodsResponse,
      dropInConfiguration,
    );

    _adyenCheckoutResultApi.dropInAdvancedFlowPlatformCommunicationStream =
        StreamController<PlatformCommunicationModel>.broadcast();
    _adyenCheckoutResultApi.dropInAdvancedFlowPlatformCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      switch (event.type) {
        case PlatformCommunicationType.paymentComponent:
          {
            if (event.data != null) {
              final Map<String, dynamic> paymentsResult =
                  await postPayments(event.data!);
              onPaymentsResult(paymentsResult);
              break;
            }
          }
        case PlatformCommunicationType.additionalDetails:
          {
            if (event.data != null) {
              final Map<String, dynamic> paymentsDetailsResult =
                  await postPaymentsDetails(event.data!);
              onPaymentsDetailsResult(paymentsDetailsResult);
              break;
            }
          }
        case PlatformCommunicationType.result:
          {
            completer.complete(event.result);
            _adyenCheckoutResultApi
                .dropInAdvancedFlowPlatformCommunicationStream
                .close();
            break;
          }
      }
    });
  }

  Future<String> getReturnUrl() async {
    return await AdyenCheckoutInterface.instance.getReturnUrl();
  }

  void onPaymentsResult(Map<String, Object?> paymentsResult) async {
    AdyenCheckoutInterface.instance.onPaymentsResult(paymentsResult);
  }

  void onPaymentsDetailsResult(
      Map<String, Object?> paymentsDetailsResult) async {
    AdyenCheckoutInterface.instance
        .onPaymentsDetailsResult(paymentsDetailsResult);
  }

  void _setupCheckoutResultApi() =>
      CheckoutResultFlutterInterface.setup(_adyenCheckoutResultApi);
}
