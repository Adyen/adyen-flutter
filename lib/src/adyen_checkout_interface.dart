import 'package:adyen_checkout/adyen_checkout.dart';

abstract class AdyenCheckoutInterface {
  Future<String> getPlatformVersion();

  Future<String> getReturnUrl();

  Future<PaymentResult> startPayment({required DropInPaymentFlow paymentFlow});

  void enableLogging({required bool loggingEnabled});
}
