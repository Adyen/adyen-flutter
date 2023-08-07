import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_platform_interface.dart';

class AdyenCheckoutPlatform extends AdyenCheckoutPlatformInterface {
  final CheckoutApi checkoutApi = CheckoutApi();

  @override
  Future<String> getPlatformVersion() {
    return checkoutApi.getPlatformVersion();
  }
}
