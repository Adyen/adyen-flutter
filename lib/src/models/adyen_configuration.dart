import 'dart:io';

import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/models/analytics_options.dart';
import 'package:adyen_checkout/src/models/payment_method_configurations/apple_pay_configuration.dart';
import 'package:adyen_checkout/src/models/payment_method_configurations/cards_configuration.dart';
import 'package:adyen_checkout/src/models/payment_method_configurations/cash_app_pay_configuration.dart';
import 'package:adyen_checkout/src/models/payment_method_configurations/google_pay_configuration.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';

sealed class AdyenConfiguration {
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final Amount amount;

  AdyenConfiguration(
    this.environment,
    this.clientKey,
    this.countryCode,
    this.amount,
  );
}

class DropInConfiguration extends DropInConfigurationDTO
    implements AdyenConfiguration {
  DropInConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required super.amount,
    String? shopperLocale,
    CardsConfiguration? cardsConfiguration,
    ApplePayConfiguration? applePayConfiguration,
    GooglePayConfiguration? googlePayConfiguration,
    CashAppPayConfiguration? cashAppPayConfiguration,
    AnalyticsOptions? analyticsOptions,
    bool showPreselectedStoredPaymentMethod = false,
    bool skipListWhenSinglePaymentMethod = false,
  }) : super(
          shopperLocale: shopperLocale ?? Platform.localeName,
          cardsConfigurationDTO: cardsConfiguration?.toDTO(),
          applePayConfigurationDTO: applePayConfiguration?.toDTO(),
          googlePayConfigurationDTO: googlePayConfiguration?.toDTO(),
          cashAppPayConfigurationDTO: cashAppPayConfiguration?.toDTO(),
          analyticsOptionsDTO: analyticsOptions?.toDTO(),
          showPreselectedStoredPaymentMethod:
              showPreselectedStoredPaymentMethod,
          skipListWhenSinglePaymentMethod: skipListWhenSinglePaymentMethod,
        );
}
