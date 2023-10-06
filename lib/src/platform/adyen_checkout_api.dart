import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_platform_interface.dart';

class AdyenCheckoutApi implements AdyenCheckoutPlatformInterface {
  final CheckoutPlatformInterface checkoutApi = CheckoutPlatformInterface();

  @override
  Future<String> getPlatformVersion() => checkoutApi.getPlatformVersion();

  @override
  void startDropInSessionPayment({
    required SessionDTO session,
    required DropInConfigurationDTO dropInConfiguration,
  }) =>
      checkoutApi.startDropInSessionPayment(
        dropInConfiguration,
        session,
      );

  @override
  void startDropInAdvancedFlowPayment({
    required String paymentMethodsResponse,
    required DropInConfigurationDTO dropInConfiguration,
  }) =>
      checkoutApi.startDropInAdvancedFlowPayment(
        dropInConfiguration,
        paymentMethodsResponse,
      );

  @override
  Future<String> getReturnUrl() => checkoutApi.getReturnUrl();

  @override
  void onPaymentsResult(DropInResultDTO paymentsResult) =>
      checkoutApi.onPaymentsResult(paymentsResult);

  @override
  void onPaymentsDetailsResult(DropInResultDTO paymentsDetailsResult) =>
      checkoutApi.onPaymentsDetailsResult(paymentsDetailsResult);

  @override
  void onDeleteStoredPaymentMethodResult(
          DeletedStoredPaymentMethodResultDTO
              deleteStoredPaymentMethodResultDTO) =>
      checkoutApi.onDeleteStoredPaymentMethodResult(
          deleteStoredPaymentMethodResultDTO);

  @override
  void enableLogging(bool loggingEnabled) {
    checkoutApi.enableLogging(loggingEnabled);
  }

  @override
  void cleanUpDropIn() => checkoutApi.cleanUpDropIn();
}
