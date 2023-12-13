import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class DropInPlatformApi implements DropInPlatformInterface {
  final DropInPlatformInterface _dropInPlatformInterface =
      DropInPlatformInterface();

  @override
  Future<void> startDropInSessionPayment(
    DropInConfigurationDTO dropInConfigurationDTO,
  ) =>
      _dropInPlatformInterface.startDropInSessionPayment(
        dropInConfigurationDTO,
      );

  @override
  Future<void> startDropInAdvancedPayment(
    DropInConfigurationDTO dropInConfiguration,
    String paymentMethodsResponse,
  ) =>
      _dropInPlatformInterface.startDropInAdvancedPayment(
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
