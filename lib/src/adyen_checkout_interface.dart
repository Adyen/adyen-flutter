import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/models/base_configuration.dart';

abstract class AdyenCheckoutInterface {
  Future<String> getPlatformVersion();

  Future<String> getReturnUrl();

  Future<Session> createSession(
    String sessionId,
    String sessionData,
    BaseConfiguration configuration,
  );

  Future<PaymentResult> startPayment({required DropInPaymentFlow paymentFlow});

  void enableLogging({required bool loggingEnabled});
}
