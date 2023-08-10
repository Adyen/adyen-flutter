import 'package:adyen_checkout/platform_api.g.dart';

class AdyenCheckoutResultApi implements CheckoutResultFlutterInterface {
  @override
  void onSessionDropInResult(SessionDropInResultModel sessionDropInResult) {
    print(sessionDropInResult);
  }
}
