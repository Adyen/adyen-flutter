import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class DropInPlatformApi implements DropInPlatformInterface {
  final DropInPlatformInterface _dropInPlatformInterface =
      DropInPlatformInterface();

  @override
  Future<void> showDropInSession(
    DropInConfigurationDTO dropInConfigurationDTO,
    SessionDTO sessionDTO,
  ) =>
      _dropInPlatformInterface.showDropInSession(
        dropInConfigurationDTO,
        sessionDTO,
      );

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
  Future<void> cleanUpDropInAdvanced() =>
      _dropInPlatformInterface.cleanUpDropInAdvanced();

  @override
  Future<void> cleanUpDropInSession() =>
      _dropInPlatformInterface.cleanUpDropInSession();
}
