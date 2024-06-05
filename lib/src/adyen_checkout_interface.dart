import 'package:adyen_checkout/src/common/model/cse/encrypted_card.dart';
import 'package:adyen_checkout/src/common/model/cse/unencrypted_card.dart';
import 'package:adyen_checkout/src/components/action_handling/model/action_component_configuration.dart';

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

  Future<Map<String, dynamic>> handleAction(
    ActionComponentConfiguration actionComponentConfiguration,
    Map<String, dynamic> action,
  );
}
