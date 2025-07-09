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

  Future<CardNumberValidationResult> validateCardNumber({
    required String cardNumber,
    bool enableLuhnCheck = true,
  });

  Future<CardExpiryDateValidationResult> validateCardExpiryDate({
    required String expiryMonth,
    required String expiryYear,
  });

  Future<CardSecurityCodeValidationResult> validateCardSecurityCode({
    required String securityCode,
    String? cardBrand,
  });

  Future<String> getThreeDS2SdkVersion();
}
