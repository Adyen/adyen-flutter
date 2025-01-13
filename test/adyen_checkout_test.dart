import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAdyenCheckoutPlatform implements CheckoutPlatformInterface {
  @override
  Future<String> getReturnUrl() {
    return Future.value("adyencheckout://com.adyen.adyen_checkout_example");
  }

  @override
  Future<void> enableConsoleLogging(bool loggingEnabled) async {}

  @override
  Future<SessionDTO> createSession(
    String sessionId,
    String sessionData,
    dynamic configuration,
  ) async {
    return SessionDTO(
      id: "id",
      sessionData: "sessionData",
      paymentMethodsJson: "",
    );
  }

  @override
  Future<EncryptedCardDTO> encryptCard(
      UnencryptedCardDTO unencryptedCardDTO, String publicKey) async {
    return EncryptedCardDTO(
      encryptedCardNumber: "test_5555555555554444",
      encryptedExpiryMonth: "test_03",
      encryptedExpiryYear: "test_2030",
      encryptedSecurityCode: "test_737",
    );
  }

  @override
  Future<String> encryptBin(String bin, String publicKey) async {
    return "";
  }

  @override
  Future<void> clearSession() async {
    return;
  }

  @override
  Future<CardNumberValidationResultDTO> validateCardNumber(
    String cardNumber,
    bool enableLuhnCheck,
  ) {
    return Future.value(CardNumberValidationResultDTO.valid);
  }

  @override
  Future<CardExpiryDateValidationResultDTO> validateCardExpiryDate(
    String expiryMonth,
    String expiryYear,
  ) {
    return Future.value(CardExpiryDateValidationResultDTO.valid);
  }

  @override
  Future<CardSecurityCodeValidationResultDTO> validateCardSecurityCode(
    String securityCode,
    String? cardBrandTxVariant,
  ) {
    return Future.value(CardSecurityCodeValidationResultDTO.valid);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final AdyenCheckout initialPlatform = AdyenCheckout.instance;

  test('$AdyenCheckout is the default instance', () {
    expect(initialPlatform, isInstanceOf<AdyenCheckout>());
  });
}
