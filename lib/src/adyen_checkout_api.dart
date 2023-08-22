import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';

class AdyenCheckoutApi implements AdyenCheckoutInterface {
  final CheckoutPlatformInterface checkoutApi = CheckoutPlatformInterface();

  @override
  Future<String> getPlatformVersion() {
    return checkoutApi.getPlatformVersion();
  }

  @override
  Future<void> startPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) async {
    return checkoutApi.startPayment(sessionModel, dropInConfiguration);
  }

  @override
  Future<void> startDropInAdvancedFlowPayment(String paymentMethodsResponse,
      DropInConfigurationModel dropInConfiguration) async {
    checkoutApi.startPaymentDropInAdvancedFlow(
        paymentMethodsResponse, dropInConfiguration);
  }

  @override
  Future<String> getReturnUrl() async {
    return checkoutApi.getReturnUrl();
  }

  @override
  Future<String?> onPaymentsResult(Map<String, Object?> paymentsResult) async {
    return checkoutApi.onPaymentsResult(paymentsResult);
  }

  @override
  Future<void> onPaymentsDetailsResult(
      Map<String, Object?> paymentsDetailsResult) async {
    return checkoutApi.onPaymentsDetailsResult(paymentsDetailsResult);
  }
}
