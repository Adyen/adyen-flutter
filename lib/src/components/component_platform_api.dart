import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ComponentPlatformApi implements ComponentPlatformInterface {
  final ComponentPlatformInterface _componentPlatformInterface =
      ComponentPlatformInterface();

  @override
  Future<void> updateViewHeight(int viewId) async =>
      _componentPlatformInterface.updateViewHeight(viewId);

  @override
  Future<void> onPaymentsResult(
      PaymentOutcomeDTO paymentOutcomeDTO) async {
    _componentPlatformInterface.onPaymentsResult(paymentOutcomeDTO);
  }

  @override
  Future<void> onPaymentsDetailsResult(
      PaymentOutcomeDTO paymentOutcomeDTO) async =>
      _componentPlatformInterface
          .onPaymentsDetailsResult(paymentOutcomeDTO);
}
