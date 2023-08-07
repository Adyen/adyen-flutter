import 'package:adyen_checkout/src/adyen_checkout_platform_interface.dart';

base class AdyenCheckout {
  @override
  Future<String> getPlatformVersion() {
    return AdyenCheckoutPlatformInterface.instance.getPlatformVersion();
  }
}
