import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';

class AdyenCheckout {
  Future<String> getPlatformVersion() {
    return AdyenCheckoutInterface.instance.getPlatformVersion();
  }

  Future<void> startPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) {
    return AdyenCheckoutInterface.instance.startPayment(
      sessionModel,
      dropInConfiguration,
    );
  }
}
