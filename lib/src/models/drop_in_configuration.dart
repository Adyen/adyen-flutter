import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/models/base_configuration.dart';

final class DropInConfiguration extends BaseConfiguration {
  final CardConfiguration? cardConfiguration;
  final ApplePayConfiguration? applePayConfiguration;
  final GooglePayConfiguration? googlePayConfiguration;
  final CashAppPayConfiguration? cashAppPayConfiguration;
  final AnalyticsOptions analyticsOptions;
  final StoredPaymentMethodConfiguration? storedPaymentMethodConfiguration;
  final bool skipListWhenSinglePaymentMethod;

  DropInConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required super.amount,
    super.shopperLocale,
    this.cardConfiguration,
    this.applePayConfiguration,
    this.googlePayConfiguration,
    this.cashAppPayConfiguration,
    this.storedPaymentMethodConfiguration,
    bool? skipListWhenSinglePaymentMethod,
    AnalyticsOptions? analyticsOptions,
  })  : analyticsOptions = analyticsOptions ?? AnalyticsOptions(enabled: true),
        skipListWhenSinglePaymentMethod =
            skipListWhenSinglePaymentMethod ?? false;
}
