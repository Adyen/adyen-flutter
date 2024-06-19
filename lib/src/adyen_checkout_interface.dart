import 'package:adyen_checkout/adyen_checkout.dart';

abstract class AdyenCheckoutInterface {
  Future<String> getReturnUrl();

  void enableConsoleLogging({required bool enabled});

  Future<EncryptedCard> encryptCard(
    UnencryptedCard unencryptedCard,
    String publicKey,
  );

  Future<String> encryptBin(
    String bin,
    String publicKey,
  );

  Future<ActionResult> handleAction(
    ActionComponentConfiguration actionComponentConfiguration,
    Map<String, dynamic> action,
  );
}
