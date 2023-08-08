import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_api.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class AdyenCheckoutInterface extends PlatformInterface {
  AdyenCheckoutInterface() : super(token: _token);

  static final Object _token = Object();
  static AdyenCheckoutInterface _instance = AdyenCheckoutApi();

  static AdyenCheckoutInterface get instance => _instance;

  static set instance(AdyenCheckoutInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> getPlatformVersion();

  Future<void> startPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  );
}
