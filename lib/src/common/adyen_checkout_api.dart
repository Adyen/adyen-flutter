import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter/services.dart';

class AdyenCheckoutApi implements CheckoutPlatformInterface {
  final CheckoutPlatformInterface checkoutApi = CheckoutPlatformInterface();

  @override
  Future<String> getReturnUrl() => checkoutApi.getReturnUrl();

  @override
  Future<SessionDTO> createSession(
    String sessionId,
    String sessionData,
    dynamic configuration,
  ) =>
      checkoutApi.createSession(
        sessionId,
        sessionData,
        configuration,
      );

  @override
  Future<void> clearSession() => checkoutApi.clearSession();

  @override
  Future<void> enableConsoleLogging(bool loggingEnabled) =>
      checkoutApi.enableConsoleLogging(loggingEnabled);

  @override
  Future<EncryptedCardDTO> encryptCard(
    UnencryptedCardDTO unencryptedCardDTO,
    String publicKey,
  ) =>
      checkoutApi.encryptCard(unencryptedCardDTO, publicKey);

  @override
  Future<String> encryptBin(
    String bin,
    String publicKey,
  ) =>
      checkoutApi.encryptBin(bin, publicKey);

  @override
  Future<CardNumberValidationResultDTO> validateCardNumber(
    String cardNumber,
    bool enableLuhnCheck,
  ) =>
      checkoutApi.validateCardNumber(cardNumber, enableLuhnCheck);

  @override
  Future<CardExpiryDateValidationResultDTO> validateCardExpiryDate(
    String expiryMonth,
    String expiryYear,
  ) =>
      checkoutApi.validateCardExpiryDate(expiryMonth, expiryYear);

  @override
  Future<CardSecurityCodeValidationResultDTO> validateCardSecurityCode(
    String securityCode,
    String? cardBrand,
  ) =>
      checkoutApi.validateCardSecurityCode(securityCode, cardBrand);

  @override
  Future<String> getThreeDS2SdkVersion() => checkoutApi.getThreeDS2SdkVersion();

  @override
  // ignore: non_constant_identifier_names
  BinaryMessenger? get pigeonVar_binaryMessenger => null;

  @override
  // ignore: non_constant_identifier_names
  String get pigeonVar_messageChannelSuffix => "adyen_checkout";

  @override
  Future<SessionDTO> setupSession(SessionResponseDTO sessionResponseDTO,
          CheckoutConfigurationDTO checkoutConfigurationDTO) =>
      checkoutApi.setupSession(sessionResponseDTO, checkoutConfigurationDTO);

  @override
  Future<void> setupAdvanced(
    String paymentMethodsResponse,
    CheckoutConfigurationDTO checkoutConfigurationDTO,
  ) {
    return checkoutApi.setupAdvanced(
      paymentMethodsResponse,
      checkoutConfigurationDTO,
    );
  }
}
