import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:flutter/foundation.dart';

class SessionCheckoutRepository {
  final Service service;

  SessionCheckoutRepository({required this.service});

  String get channel =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'iOS' : 'Android';

  String determineReturnUrl({TargetPlatform? platform}) {
    if ((platform ?? defaultTargetPlatform) == TargetPlatform.android) {
      return Config.androidReturnUrl;
    }
    return Config.iosReturnUrl;
  }

  CheckoutConfiguration buildConfiguration() => const CheckoutConfiguration(
        environment: Config.environment,
        clientKey: Config.clientKey,
        amount: Config.amount,
        countryCode: Config.countryCode,
        cardConfiguration: CardConfiguration(
          showCardholderName: true,
          showStorePaymentMethod: false,
          showSupportedCardBrandLogos: true,
        ),
        googlePayConfiguration: GooglePayConfiguration(
          googlePayEnvironment: Config.googlePayEnvironment,
          emailRequired: true,
        ),
        applePayConfiguration: ApplePayConfiguration(
          merchantId: Config.merchantId,
          merchantName: Config.merchantName,
          buttonStyle: ApplePayButtonStyle(type: ApplePayButtonType.buy),
          buttonWidth: 200,
          buttonHeight: 48,
        ),
      );

  Future<SessionResponse> createSessionResponse() async {
    final response = await service.createSession({
      'merchantAccount': Config.merchantAccount,
      'amount': Config.amount.toJson(),
      'countryCode': Config.countryCode,
      'shopperLocale': Config.shopperLocale,
      'returnUrl': determineReturnUrl(),
      'lineItems': Config.lineItems,
      'reference': 'flutter-session-${DateTime.now().millisecondsSinceEpoch}',
      'channel': channel,
    });
    return SessionResponse.fromJson(response);
  }

  Future<SessionCheckout> setupCheckout({
    required SessionCheckoutCallbacks callbacks,
  }) async {
    final sessionResponse = await createSessionResponse();
    return Checkout.instance.setup(
      sessionResponse: sessionResponse,
      configuration: buildConfiguration(),
      callbacks: callbacks,
    );
  }
}
