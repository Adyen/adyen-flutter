import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_platform_interface.dart';

class AdyenCheckoutApi implements AdyenCheckoutPlatformInterface {
  final CheckoutPlatformInterface checkoutApi = CheckoutPlatformInterface();

  @override
  Future<String> getPlatformVersion() => checkoutApi.getPlatformVersion();

  @override
  Future<String> getReturnUrl() => checkoutApi.getReturnUrl();

  @override
  Future<void> startDropInSessionPayment(
    DropInConfigurationDTO dropInConfigurationDTO,
    SessionDTO session,
  ) =>
      checkoutApi.startDropInSessionPayment(
        dropInConfigurationDTO,
        session,
      );

  @override
  Future<void> startDropInAdvancedFlowPayment(
    DropInConfigurationDTO dropInConfiguration,
    String paymentMethodsResponse,
  ) =>
      checkoutApi.startDropInAdvancedFlowPayment(
        dropInConfiguration,
        paymentMethodsResponse,
      );

  @override
  Future<void> onPaymentsResult(PaymentFlowOutcomeDTO paymentsResult) =>
      checkoutApi.onPaymentsResult(paymentsResult);

  @override
  Future<void> onPaymentsDetailsResult(
          PaymentFlowOutcomeDTO paymentsDetailsResult) =>
      checkoutApi.onPaymentsDetailsResult(paymentsDetailsResult);

  @override
  Future<void> onDeleteStoredPaymentMethodResult(
          DeletedStoredPaymentMethodResultDTO
              deleteStoredPaymentMethodResultDTO) =>
      checkoutApi.onDeleteStoredPaymentMethodResult(
          deleteStoredPaymentMethodResultDTO);

  @override
  Future<void> enableLogging(bool loggingEnabled) =>
      checkoutApi.enableLogging(loggingEnabled);

  @override
  Future<void> cleanUpDropIn() => checkoutApi.cleanUpDropIn();
}
