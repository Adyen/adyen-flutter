import 'generated/platform_api.g.dart';

abstract interface class CheckoutGateway {
  Stream<CheckoutEventDTO> get events;

  Future<CheckoutSetupResultDTO> setupSession(
    SessionResponseDTO sessionResponse,
    CheckoutConfigurationDTO configuration,
  );

  Future<CheckoutSetupResultDTO> setupAdvanced(
    String paymentMethodsJson,
    CheckoutConfigurationDTO configuration,
  );

  Future<void> disposeCheckout(String checkoutId);

  Future<AdvancedCheckoutResultDTO> handleAction(
    String actionId,
    String actionJson,
    CheckoutConfigurationDTO configuration,
  );

  Future<void> enableConsoleLogging(bool enabled);

  Future<EncryptedCardDTO> encryptCard(
    UnencryptedCardDTO card,
    String publicKey,
  );

  Future<String> encryptBin(String bin, String publicKey);

  Future<bool> validateCardNumber(String cardNumber, bool enableLuhnCheck);

  Future<bool> validateCardExpiryDate(String expiryMonth, String expiryYear);

  Future<bool> validateCardSecurityCode(String securityCode, String? cardBrand);

  Future<String> getThreeDS2SdkVersion();

  Future<void> submit(String checkoutId, String componentId);

  Future<void> disposeComponent(String checkoutId, String componentId);
}

Stream<CheckoutEventDTO> _checkoutEvents() => events();

class NativeCheckoutGateway implements CheckoutGateway {
  final CheckoutHostApi _checkoutHostApi;
  final ComponentHostApi _componentHostApi;

  NativeCheckoutGateway({
    CheckoutHostApi? checkoutHostApi,
    ComponentHostApi? componentHostApi,
  })  : _checkoutHostApi = checkoutHostApi ?? CheckoutHostApi(),
        _componentHostApi = componentHostApi ?? ComponentHostApi();

  @override
  Stream<CheckoutEventDTO> get events => _checkoutEvents();

  @override
  Future<CheckoutSetupResultDTO> setupSession(
    SessionResponseDTO sessionResponse,
    CheckoutConfigurationDTO configuration,
  ) =>
      _checkoutHostApi.setupSession(sessionResponse, configuration);

  @override
  Future<CheckoutSetupResultDTO> setupAdvanced(
    String paymentMethodsJson,
    CheckoutConfigurationDTO configuration,
  ) =>
      _checkoutHostApi.setupAdvanced(paymentMethodsJson, configuration);

  @override
  Future<void> disposeCheckout(String checkoutId) =>
      _checkoutHostApi.disposeCheckout(checkoutId);

  @override
  Future<AdvancedCheckoutResultDTO> handleAction(
    String actionId,
    String actionJson,
    CheckoutConfigurationDTO configuration,
  ) =>
      _checkoutHostApi.handleAction(actionId, actionJson, configuration);

  @override
  Future<void> enableConsoleLogging(bool enabled) =>
      _checkoutHostApi.enableConsoleLogging(enabled);

  @override
  Future<EncryptedCardDTO> encryptCard(
    UnencryptedCardDTO card,
    String publicKey,
  ) =>
      _checkoutHostApi.encryptCard(card, publicKey);

  @override
  Future<String> encryptBin(String bin, String publicKey) =>
      _checkoutHostApi.encryptBin(bin, publicKey);

  @override
  Future<bool> validateCardNumber(String cardNumber, bool enableLuhnCheck) =>
      _checkoutHostApi.validateCardNumber(cardNumber, enableLuhnCheck);

  @override
  Future<bool> validateCardExpiryDate(String expiryMonth, String expiryYear) =>
      _checkoutHostApi.validateCardExpiryDate(expiryMonth, expiryYear);

  @override
  Future<bool> validateCardSecurityCode(
          String securityCode, String? cardBrand) =>
      _checkoutHostApi.validateCardSecurityCode(securityCode, cardBrand);

  @override
  Future<String> getThreeDS2SdkVersion() =>
      _checkoutHostApi.getThreeDS2SdkVersion();

  @override
  Future<void> submit(String checkoutId, String componentId) =>
      _componentHostApi.submit(checkoutId, componentId);

  @override
  Future<void> disposeComponent(String checkoutId, String componentId) =>
      _componentHostApi.dispose(checkoutId, componentId);
}
