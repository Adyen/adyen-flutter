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
  Future<void> onPaymentsResult(PaymentOutcomeDTO paymentsResult) =>
      _dropInPlatformInterface.onPaymentsResult(paymentsResult);

  @override
  Future<void> onPaymentsDetailsResult(
          PaymentOutcomeDTO paymentsDetailsResult) =>
      _dropInPlatformInterface.onPaymentsDetailsResult(paymentsDetailsResult);

  @override
  Future<void> onDeleteStoredPaymentMethodResult(
          DeletedStoredPaymentMethodResultDTO
              deleteStoredPaymentMethodResultDTO) =>
      _dropInPlatformInterface.onDeleteStoredPaymentMethodResult(
          deleteStoredPaymentMethodResultDTO);

  @override
  Future<void> cleanUpDropIn() => _dropInPlatformInterface.cleanUpDropIn();
}
