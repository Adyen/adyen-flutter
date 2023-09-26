import 'dart:io';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/models/analytics_options.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';

sealed class AdyenConfiguration {
  final Environment environment;
  final String clientKey;
  final String countryCode;

  AdyenConfiguration(
    this.environment,
    this.clientKey,
    this.countryCode,
  );
}

class DropInConfiguration extends DropInConfigurationDTO
    implements AdyenConfiguration {
  DropInConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required Amount amount,
    String? shopperLocale,
    CardsConfiguration? cardsConfiguration,
    ApplePayConfiguration? applePayConfiguration,
    GooglePayConfiguration? googlePayConfiguration,
    CashAppPayConfiguration? cashAppPayConfiguration,
    AnalyticsOptions? analyticsOptions,
    bool showPreselectedStoredPaymentMethod = false,
    bool skipListWhenSinglePaymentMethod = false,
  }) : super(
          amount: amount.toDTO(),
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
