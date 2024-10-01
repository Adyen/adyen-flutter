import 'package:adyen_checkout/src/generated/platform_api.g.dart';

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
  Future<void> invalidateSession() => checkoutApi.invalidateSession();

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
}
