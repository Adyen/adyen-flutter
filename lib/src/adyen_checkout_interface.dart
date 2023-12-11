import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/models/base_configuration.dart';

abstract class AdyenCheckoutInterface {
  Future<String> getReturnUrl();

  Future<Session> createSession({
    required String sessionId,
    required String sessionData,
    required BaseConfiguration configuration,
  });

  Future<PaymentResult> startPayment({required DropInPaymentFlow paymentFlow});

  void enableConsoleLogging({required bool enabled});
}
