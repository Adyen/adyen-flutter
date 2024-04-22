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
  Future<String> encrypt(
      UnencryptedCardDTO unencryptedCardDTO, String publicKey) {
    // TODO: implement encrypt
    throw UnimplementedError();
  }

  @override
  Future<EncryptedCardDTO> encryptCard(
      UnencryptedCardDTO unencryptedCardDTO, String publicKey) {
    // TODO: implement encryptCard
    throw UnimplementedError();
  }

  @override
  Future<String> encryptBin(String bin, String publicKey) {
    // TODO: implement encryptBin
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final AdyenCheckout initialPlatform = AdyenCheckout.instance;

  test('$AdyenCheckout is the default instance', () {
    expect(initialPlatform, isInstanceOf<AdyenCheckout>());
  });
}
