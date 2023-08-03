
import 'adyen_checkout_platform_interface.dart';

class AdyenCheckout {
  Future<String?> getPlatformVersion() {
    return AdyenCheckoutPlatform.instance.getPlatformVersion();
  }
}
