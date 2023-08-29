import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_platform_interface.dart';

class AdyenCheckoutApi implements AdyenCheckoutPlatformInterface {
  final CheckoutPlatformInterface checkoutApi = CheckoutPlatformInterface();

  @override
  Future<String> getPlatformVersion() => checkoutApi.getPlatformVersion();

  @override
  void startDropInSessionPayment(
    Session session,
    DropInConfiguration dropInConfiguration,
  ) =>
      checkoutApi.startDropInSessionPayment(
        dropInConfiguration,
        session,
      );

  @override
  void startDropInAdvancedFlowPayment(
    String paymentMethodsResponse,
    DropInConfiguration dropInConfiguration,
  ) =>
      checkoutApi.startDropInAdvancedFlowPayment(
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
