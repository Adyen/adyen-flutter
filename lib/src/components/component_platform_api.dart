import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ComponentPlatformApi implements ComponentPlatformInterface {
  final ComponentPlatformInterface _componentPlatformInterface =
      ComponentPlatformInterface();

  @override
  Future<void> updateViewHeight(int viewId) async =>
      _componentPlatformInterface.updateViewHeight(viewId);

  @override
  Future<void> onPaymentsResult(
      PaymentFlowOutcomeDTO paymentFlowOutcomeDTO) async {
    _componentPlatformInterface.onPaymentsResult(paymentFlowOutcomeDTO);
  }

  @override
  Future<void> onPaymentsDetailsResult(
          PaymentFlowOutcomeDTO paymentFlowOutcomeDTO) async =>
      _componentPlatformInterface
          .onPaymentsDetailsResult(paymentFlowOutcomeDTO);
}
