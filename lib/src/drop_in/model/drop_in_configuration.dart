import 'package:adyen_checkout/src/common/model/analytics_options.dart';
import 'package:adyen_checkout/src/common/model/base_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/card_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/cash_app_pay_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/google_pay/google_pay_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/stored_payment_method_configuration.dart';

final class DropInConfiguration extends BaseConfiguration {
  final CardConfiguration? cardConfiguration;
  final ApplePayConfiguration? applePayConfiguration;
  final GooglePayConfiguration? googlePayConfiguration;
  final CashAppPayConfiguration? cashAppPayConfiguration;
  final StoredPaymentMethodConfiguration? storedPaymentMethodConfiguration;
  final bool skipListWhenSinglePaymentMethod;
  final String? preselectedPaymentMethodTitle;

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
    this.preselectedPaymentMethodTitle,
    bool? skipListWhenSinglePaymentMethod,
    AnalyticsOptions? analyticsOptions,
  }) : skipListWhenSinglePaymentMethod =
            skipListWhenSinglePaymentMethod ?? false;
}
