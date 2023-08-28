import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/platform_api.g.dart';

abstract class AdyenCheckoutInterface {
  Future<String> getPlatformVersion();

  Future<String> getReturnUrl();

  Future<DropInResultModel> startPayment({required PaymentFlow paymentFlow});
}
