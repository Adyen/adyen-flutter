import 'package:adyen_checkout/src/common/model/cse/encrypted_card.dart';
import 'package:adyen_checkout/src/common/model/cse/unencrypted_card.dart';

abstract class AdyenCheckoutInterface {
  Future<String> getReturnUrl();

  void enableConsoleLogging({required bool enabled});

  Future<EncryptedCard> encryptCard(
    UnencryptedCard unencryptedCard,
    String publicKey,
  );

  Future<String> encrypt(
    UnencryptedCard unencryptedCard,
    String publicKey,
  );

  Future<String> encryptBin(
    String bin,
    String publicKey,
  );
}
