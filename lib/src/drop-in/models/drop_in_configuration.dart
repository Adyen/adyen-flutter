import 'package:adyen_checkout/src/common/models/analytics_options.dart';
import 'package:adyen_checkout/src/common/models/base_configuration.dart';
import 'package:adyen_checkout/src/common/models/payment_method_configurations/apple_pay_configuration.dart';
import 'package:adyen_checkout/src/common/models/payment_method_configurations/card_configuration.dart';
import 'package:adyen_checkout/src/common/models/payment_method_configurations/cash_app_pay_configuration.dart';
import 'package:adyen_checkout/src/common/models/payment_method_configurations/google_pay_configuration.dart';
import 'package:adyen_checkout/src/common/models/stored_payment_method_configuration.dart';

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
