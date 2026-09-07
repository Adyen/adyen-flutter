import 'checkout_coordinator.dart';
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

abstract final class Checkout {
  static CheckoutCoordinator get _coordinator => CheckoutCoordinator.shared;

  static Future<SessionCheckout> setup({
    required SessionResponse sessionResponse,
    required CheckoutConfiguration configuration,
    required SessionCheckoutCallbacks callbacks,
  }) =>
      _coordinator.setupSession(
        sessionResponse: sessionResponse,
        configuration: configuration,
        callbacks: callbacks,
      );

  static Future<AdvancedCheckout> setupAdvanced({
    required PaymentMethods paymentMethods,
    required CheckoutConfiguration configuration,
    required AdvancedCheckoutCallbacks callbacks,
  }) =>
      _coordinator.setupAdvanced(
        paymentMethods: paymentMethods,
        configuration: configuration,
        callbacks: callbacks,
      );

  static Future<AdvancedCheckoutResult> handleAction({
    required Action action,
    required CheckoutConfiguration configuration,
    required Future<AdditionalDetailsResult> Function(
      ActionComponentData data,
    ) onAdditionalDetails,
  }) =>
      _coordinator.handleAction(
        action: action,
        configuration: configuration,
        onAdditionalDetails: onAdditionalDetails,
      );

  static Future<void> enableConsoleLogging({required bool enabled}) =>
      _coordinator.enableConsoleLogging(enabled: enabled);

  static Future<EncryptedCard> encryptCard({
    required UnencryptedCard card,
    required String publicKey,
  }) =>
      _coordinator.encryptCard(card: card, publicKey: publicKey);

  static Future<String> encryptBin({
    required String bin,
    required String publicKey,
  }) =>
      _coordinator.encryptBin(bin: bin, publicKey: publicKey);

  static Future<bool> validateCardNumber({
    required String cardNumber,
    bool enableLuhnCheck = true,
  }) =>
      _coordinator.validateCardNumber(
        cardNumber: cardNumber,
        enableLuhnCheck: enableLuhnCheck,
      );

  static Future<bool> validateCardExpiryDate({
    required String expiryMonth,
    required String expiryYear,
  }) =>
      _coordinator.validateCardExpiryDate(
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
      );

  static Future<bool> validateCardSecurityCode({
    required String securityCode,
    String? cardBrand,
  }) =>
      _coordinator.validateCardSecurityCode(
        securityCode: securityCode,
        cardBrand: cardBrand,
      );

  static Future<String> getThreeDS2SdkVersion() =>
      _coordinator.getThreeDS2SdkVersion();
}
