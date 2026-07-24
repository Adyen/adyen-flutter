import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/drop_in/accessibility/adyen_drop_in_focus_scope.dart';
import 'package:adyen_checkout/src/drop_in/accessibility/drop_in_focus_state.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

  @override
  Future<String> getThreeDS2SdkVersion() {
    return Future.value("2.2.0");
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final AdyenCheckout initialPlatform = AdyenCheckout.instance;

  test('$AdyenCheckout is the default instance', () {
    expect(initialPlatform, isInstanceOf<AdyenCheckout>());
  });

  testWidgets('blocks Flutter focus while Drop-in is active on iOS',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    DropInFocusState.activate();
    final focusNode = FocusNode();
    addTearDown(() => DropInFocusState.deactivate());
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      AdyenDropInFocusScope(
        child: Focus(focusNode: focusNode, child: const SizedBox()),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('keeps Flutter focus unchanged on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    DropInFocusState.activate();
    final focusNode = FocusNode();
    addTearDown(() => DropInFocusState.deactivate());
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      AdyenDropInFocusScope(
        child: Focus(focusNode: focusNode, child: const SizedBox()),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });
}
