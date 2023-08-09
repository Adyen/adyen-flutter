import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';

class AdyenCheckoutApi implements AdyenCheckoutInterface {
  final CheckoutPlatformApiInterface checkoutApi = CheckoutPlatformApiInterface();

  @override
  Future<String> getPlatformVersion() {
    return checkoutApi.getPlatformVersion();
  }

  @override
  Future<void> startPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) {
    return checkoutApi.startPayment(sessionModel, dropInConfiguration);
  }
}
