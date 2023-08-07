
import 'package:adyen_checkout/platform_api.g.dart';

class AdyenCheckout {
  final CheckoutApi adyenCheckout = CheckoutApi();

  Future<String?> getPlatformVersionPigeon() {
    return adyenCheckout.getPlatformVersion();
  }

}
