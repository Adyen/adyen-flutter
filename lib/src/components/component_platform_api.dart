import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ComponentPlatformApi implements ComponentPlatformInterface {
  final ComponentPlatformInterface _componentPlatformInterface =
      ComponentPlatformInterface();

  @override
  Future<void> updateViewHeight(int viewId) async =>
      _componentPlatformInterface.updateViewHeight(viewId);

  @override
  Future<void> onPaymentsResult(PaymentEventDTO paymentEventDTO) async {
    _componentPlatformInterface.onPaymentsResult(paymentEventDTO);
  }

  @override
  Future<void> onPaymentsDetailsResult(PaymentEventDTO paymentEventDTO) async =>
      _componentPlatformInterface.onPaymentsDetailsResult(paymentEventDTO);
}
