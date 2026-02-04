import 'package:adyen_checkout/adyen_checkout.dart';

class CheckoutConfiguration {
  final Environment environment;
  final String clientKey;
  final String? countryCode;
  final Amount? amount;
  final String? shopperLocale;
  final AnalyticsOptions? analyticsOptions;
  final CardConfiguration? cardConfiguration;
  final ApplePayConfiguration? applePayConfiguration;
  final GooglePayConfiguration? googlePayConfiguration;
  final CashAppPayConfiguration? cashAppPayConfiguration;
  final TwintConfiguration? twintConfiguration;
  final ThreeDS2Configuration? threeDS2Configuration;
  final DropInConfiguration? dropInConfiguration;

  CheckoutConfiguration({
    required this.environment,
    required this.clientKey,
    this.countryCode,
    this.amount,
    this.shopperLocale,
    this.analyticsOptions,
    this.cardConfiguration,
    this.applePayConfiguration,
    this.googlePayConfiguration,
    this.cashAppPayConfiguration,
    this.twintConfiguration,
    this.threeDS2Configuration,
    this.dropInConfiguration,
  });
}
