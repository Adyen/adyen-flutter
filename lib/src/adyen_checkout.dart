import 'checkout_runtime.dart';
import 'common/model/action.dart';
import 'common/model/action_component_data.dart';
import 'common/model/checkout_callbacks.dart';
import 'common/model/checkout_configuration.dart';
import 'common/model/checkout.dart';
import 'common/model/checkout_results.dart';
import 'common/model/cse/encrypted_card.dart';
import 'common/model/cse/unencrypted_card.dart';
import 'common/model/payment_methods.dart';
import 'common/model/session_response.dart';

final class Checkout {
  static final Checkout _defaultInstance = Checkout._();
  static Checkout get instance => _defaultInstance;

  late final CheckoutRuntime _runtime = CheckoutRuntime();

  Checkout._();

  Future<SessionCheckout> setup({
    required SessionResponse sessionResponse,
    required CheckoutConfiguration configuration,
    required SessionCheckoutCallbacks callbacks,
  }) =>
      _runtime.setupSession(
        sessionResponse: sessionResponse,
        configuration: configuration,
        callbacks: callbacks,
      );

  Future<AdvancedCheckout> setupAdvanced({
    required PaymentMethods paymentMethods,
    required CheckoutConfiguration configuration,
    required AdvancedCheckoutCallbacks callbacks,
  }) =>
      _runtime.setupAdvanced(
        paymentMethods: paymentMethods,
        configuration: configuration,
        callbacks: callbacks,
      );

  Future<AdvancedCheckoutResult> handleAction({
    required Action action,
    required CheckoutConfiguration configuration,
    required Future<AdditionalDetailsResult> Function(
      ActionComponentData data,
    ) onAdditionalDetails,
  }) =>
      _runtime.handleAction(
        action: action,
        configuration: configuration,
        onAdditionalDetails: onAdditionalDetails,
      );

  Future<void> enableConsoleLogging({required bool enabled}) =>
      _runtime.enableConsoleLogging(enabled: enabled);

  Future<EncryptedCard> encryptCard({
    required UnencryptedCard card,
    required String publicKey,
  }) =>
      _runtime.encryptCard(card: card, publicKey: publicKey);

  Future<String> encryptBin({
    required String bin,
    required String publicKey,
  }) =>
      _runtime.encryptBin(bin: bin, publicKey: publicKey);

  Future<bool> validateCardNumber({
    required String cardNumber,
    bool enableLuhnCheck = true,
  }) =>
      _runtime.validateCardNumber(
        cardNumber: cardNumber,
        enableLuhnCheck: enableLuhnCheck,
      );

  Future<bool> validateCardExpiryDate({
    required String expiryMonth,
    required String expiryYear,
  }) =>
      _runtime.validateCardExpiryDate(
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
      );

  Future<bool> validateCardSecurityCode({
    required String securityCode,
    String? cardBrand,
  }) =>
      _runtime.validateCardSecurityCode(
        securityCode: securityCode,
        cardBrand: cardBrand,
      );

  Future<String> getThreeDS2SdkVersion() =>
      _runtime.getThreeDS2SdkVersion();
}
