import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ComponentPlatformApi implements ComponentPlatformInterface {
  ComponentPlatformApi._init();

  static ComponentPlatformApi? _instance;

  static ComponentPlatformApi get instance =>
      _instance ??= ComponentPlatformApi._init();

  final ComponentPlatformInterface _componentPlatformInterface =
      ComponentPlatformInterface();

  @override
  Future<void> updateViewHeight(int viewId) async =>
      _componentPlatformInterface.updateViewHeight(viewId);

  @override
  Future<void> onPaymentsResult(
    PaymentEventDTO paymentEventDTO,
    String componentId,
  ) async {
    _componentPlatformInterface.onPaymentsResult(
      paymentEventDTO,
      componentId,
    );
  }

  @override
  Future<void> onPaymentsDetailsResult(
    PaymentEventDTO paymentEventDTO,
    String componentId,
  ) async =>
      _componentPlatformInterface.onPaymentsDetailsResult(
        paymentEventDTO,
        componentId,
      );

  @override
  Future<InstantPaymentSetupResultDTO> isInstantPaymentSupportedByPlatform(
    InstantPaymentConfigurationDTO instantPaymentConfigurationDTO,
    String paymentMethodResponse,
    String componentId,
  ) async =>
      _componentPlatformInterface.isInstantPaymentSupportedByPlatform(
        instantPaymentConfigurationDTO,
        paymentMethodResponse,
        componentId,
      );

  @override
  Future<void> onInstantPaymentPressed(
    InstantPaymentType instantPaymentType,
    String componentId,
  ) async =>
      _componentPlatformInterface.onInstantPaymentPressed(
        instantPaymentType,
        componentId,
      );

  @override
  Future<void> onDispose(String componentId) async =>
      _componentPlatformInterface.onDispose(componentId);
}
