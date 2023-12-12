import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class DropInPlatformApi implements DropInPlatformInterface {
  final DropInPlatformInterface _dropInPlatformInterface =
      DropInPlatformInterface();

  @override
  Future<void> startDropInSessionPayment(
    DropInConfigurationDTO dropInConfigurationDTO,
    SessionDTO session,
  ) =>
      _dropInPlatformInterface.startDropInSessionPayment(
        dropInConfigurationDTO,
        session,
      );

  @override
  Future<void> startDropInAdvancedFlowPayment(
    DropInConfigurationDTO dropInConfiguration,
    String paymentMethodsResponse,
  ) =>
      _dropInPlatformInterface.startDropInAdvancedFlowPayment(
        dropInConfiguration,
        paymentMethodsResponse,
      );

  @override
  Future<void> onPaymentsResult(PaymentFlowOutcomeDTO paymentsResult) =>
      _dropInPlatformInterface.onPaymentsResult(paymentsResult);

  @override
  Future<void> onPaymentsDetailsResult(
          PaymentFlowOutcomeDTO paymentsDetailsResult) =>
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
