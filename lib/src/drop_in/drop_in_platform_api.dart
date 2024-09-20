import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class DropInPlatformApi implements DropInPlatformInterface {
  final DropInPlatformInterface _dropInPlatformInterface =
      DropInPlatformInterface();

  @override
  Future<void> showDropInSession(
    DropInConfigurationDTO dropInConfigurationDTO,
  ) =>
      _dropInPlatformInterface.showDropInSession(dropInConfigurationDTO);

  @override
  Future<void> showDropInAdvanced(
    DropInConfigurationDTO dropInConfiguration,
    String paymentMethodsResponse,
  ) =>
      _dropInPlatformInterface.showDropInAdvanced(
        dropInConfiguration,
        paymentMethodsResponse,
      );

  @override
  Future<void> onPaymentsResult(PaymentEventDTO paymentsResult) =>
      _dropInPlatformInterface.onPaymentsResult(paymentsResult);

  @override
  Future<void> onPaymentsDetailsResult(PaymentEventDTO paymentsDetailsResult) =>
      _dropInPlatformInterface.onPaymentsDetailsResult(paymentsDetailsResult);

  @override
  Future<void> onDeleteStoredPaymentMethodResult(
          DeletedStoredPaymentMethodResultDTO
              deleteStoredPaymentMethodResultDTO) =>
      _dropInPlatformInterface.onDeleteStoredPaymentMethodResult(
          deleteStoredPaymentMethodResultDTO);

  @override
  Future<void> cleanUpDropIn() => _dropInPlatformInterface.cleanUpDropIn();

  @override
  Future<void> onBalanceCheckResult(String balanceCheckResponse) =>
      _dropInPlatformInterface.onBalanceCheckResult(balanceCheckResponse);

  @override
  Future<void> onOrderRequestResult(String orderRequestResponse) =>
      _dropInPlatformInterface.onOrderRequestResult(orderRequestResponse);
}
