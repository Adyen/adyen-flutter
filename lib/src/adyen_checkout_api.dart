import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';

class AdyenCheckoutApi implements AdyenCheckoutInterface {
  final CheckoutPlatformInterface checkoutApi = CheckoutPlatformInterface();

  @override
  Future<String> getPlatformVersion() => checkoutApi.getPlatformVersion();

  @override
  void startPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) =>
      checkoutApi.startPayment(
        dropInConfiguration,
        sessionModel,
      );

  @override
  void startDropInAdvancedFlowPayment(
    String paymentMethodsResponse,
    DropInConfigurationModel dropInConfiguration,
  ) =>
      checkoutApi.startPaymentDropInAdvancedFlow(
        dropInConfiguration,
        paymentMethodsResponse,
      );

  @override
  Future<String> getReturnUrl() => checkoutApi.getReturnUrl();

  @override
  void onPaymentsResult(Map<String, Object?> paymentsResult) =>
      checkoutApi.onPaymentsResult(paymentsResult);

  @override
  void onPaymentsDetailsResult(Map<String, Object?> paymentsDetailsResult) =>
      checkoutApi.onPaymentsDetailsResult(paymentsDetailsResult);
}
