import 'package:adyen_checkout/src/adyen_checkout_platform.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class AdyenCheckoutPlatformInterface extends PlatformInterface {
  AdyenCheckoutPlatformInterface() : super(token: _token);

  static final Object _token = Object();
  static AdyenCheckoutPlatformInterface _instance = AdyenCheckoutPlatform();

  static AdyenCheckoutPlatformInterface get instance => _instance;

  static set instance(AdyenCheckoutPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> getPlatformVersion();
}
