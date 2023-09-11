import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_platform_interface.dart';

class AdyenCheckoutApi implements AdyenCheckoutPlatformInterface {
  final CheckoutPlatformInterface checkoutApi = CheckoutPlatformInterface();

  @override
  Future<String> getPlatformVersion() => checkoutApi.getPlatformVersion();

  @override
  void startDropInSessionPayment(
    Session session,
    Configuration dropInConfiguration,
  ) =>
      checkoutApi.startDropInSessionPayment(
        dropInConfiguration,
        session,
      );

  @override
  void startDropInAdvancedFlowPayment(
    String paymentMethodsResponse,
    Configuration dropInConfiguration,
  ) =>
      checkoutApi.startDropInAdvancedFlowPayment(
        dropInConfiguration,
        paymentMethodsResponse,
      );

  @override
  Future<String> getReturnUrl() => checkoutApi.getReturnUrl();

  @override
  void onPaymentsResult(DropInResult paymentsResult) =>
      checkoutApi.onPaymentsResult(paymentsResult);

  @override
  void onPaymentsDetailsResult(DropInResult paymentsDetailsResult) =>
      checkoutApi.onPaymentsDetailsResult(paymentsDetailsResult);
}
