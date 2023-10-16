import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/models/analytics_options.dart';

class DropInConfiguration {
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final Amount amount;
  final String? shopperLocale;
  final CardsConfiguration? cardsConfiguration;
  final ApplePayConfiguration? applePayConfiguration;
  final GooglePayConfiguration? googlePayConfiguration;
  final CashAppPayConfiguration? cashAppPayConfiguration;
  final AnalyticsOptions? analyticsOptions;
  final StoredPaymentMethodConfiguration? storedPaymentMethodConfiguration;
  final bool skipListWhenSinglePaymentMethod;

  DropInConfiguration({
    required this.environment,
    required this.clientKey,
    required this.countryCode,
    required this.amount,
    this.shopperLocale,
    this.cardsConfiguration,
    this.applePayConfiguration,
    this.googlePayConfiguration,
    this.cashAppPayConfiguration,
    this.analyticsOptions,
    this.storedPaymentMethodConfiguration,
    this.skipListWhenSinglePaymentMethod = false,
  });
}
