import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class AdyenComponentApi implements ComponentPlatformInterface {
  final ComponentPlatformInterface _componentPlatformInterface =
      ComponentPlatformInterface();

  @override
  Future<void> onAction(Map<String?, Object?>? actionResponse) async =>
      _componentPlatformInterface.onAction(actionResponse);

  @override
  Future<void> updateViewHeight(int viewId) async =>
      _componentPlatformInterface.updateViewHeight(viewId);
}
