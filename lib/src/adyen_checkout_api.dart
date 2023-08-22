import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';

class AdyenCheckoutApi implements AdyenCheckoutInterface {
  final CheckoutPlatformInterface checkoutApi = CheckoutPlatformInterface();

  @override
  Future<String> getPlatformVersion() {
    return checkoutApi.getPlatformVersion();
  }

  @override
  void startPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) {
    checkoutApi.startPayment(sessionModel, dropInConfiguration);
  }

  @override
  void startDropInAdvancedFlowPayment(String paymentMethodsResponse,
      DropInConfigurationModel dropInConfiguration) async {
    checkoutApi.startPaymentDropInAdvancedFlow(
        paymentMethodsResponse, dropInConfiguration);
  }

  @override
  Future<String> getReturnUrl() async {
    return checkoutApi.getReturnUrl();
  }

  @override
  void onPaymentsResult(Map<String, Object?> paymentsResult) {
    checkoutApi.onPaymentsResult(paymentsResult);
  }

  @override
  void onPaymentsDetailsResult(Map<String, Object?> paymentsDetailsResult) {
    checkoutApi.onPaymentsDetailsResult(paymentsDetailsResult);
  }
}
