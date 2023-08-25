import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/adyen_checkout_result_api.dart';

class AdyenCheckout {
  AdyenCheckout() {
    _setupResultApi();
  }

  final AdyenCheckoutResultApi _resultApi = AdyenCheckoutResultApi();

  Future<String> getPlatformVersion() =>
      AdyenCheckoutInterface.instance.getPlatformVersion();

  Future<DropInResultModel> startPayment({
    required DropInConfigurationModel dropInConfiguration,
    SessionModel? sessionModel,
    String? paymentMethodsResponse,
    Future<Map<String, dynamic>> Function(String paymentComponentJson)?
        postPayments,
    Future<Map<String, dynamic>> Function(String additionalDetailsJson)?
        postPaymentsDetails,
  }) async {
    if (sessionModel != null) {
      return await _startDropInSessionsPayment(
        sessionModel,
        dropInConfiguration,
      );
    }

    if (paymentMethodsResponse != null &&
        postPayments != null &&
        postPaymentsDetails != null) {
      return await _startDropInAdvancedFlowPayment(
        paymentMethodsResponse,
        dropInConfiguration,
        (paymentComponentJson) => postPayments(paymentComponentJson),
        (additionalDetailsJson) => postPaymentsDetails(additionalDetailsJson),
      );
    }

    throw Exception("Wrong method parameters provided");
  }

  Future<DropInResultModel> _startDropInSessionsPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) async {
    _resultApi.dropInSessionResultStream =
        StreamController<DropInResultModel>();
    AdyenCheckoutInterface.instance.startPayment(
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
    AdyenCheckoutInterface.instance.startDropInAdvancedFlowPayment(
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
      onPaymentsDetailsResult(paymentsDetailsResult);
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
      onPaymentsResult(paymentsResult);
    }
  }

  Future<String> getReturnUrl() =>
      AdyenCheckoutInterface.instance.getReturnUrl();

  void onPaymentsResult(Map<String, Object?> paymentsResult) =>
      AdyenCheckoutInterface.instance.onPaymentsResult(paymentsResult);

  void onPaymentsDetailsResult(Map<String, Object?> paymentsDetailsResult) =>
      AdyenCheckoutInterface.instance
          .onPaymentsDetailsResult(paymentsDetailsResult);

  void _setupResultApi() => CheckoutFlutterApi.setup(_resultApi);
}
