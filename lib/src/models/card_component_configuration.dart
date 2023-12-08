import 'package:adyen_checkout/src/models/analytics_options.dart';
import 'package:adyen_checkout/src/models/base_configuration.dart';
import 'package:adyen_checkout/src/models/payment_method_configurations/card_configuration.dart';

final class CardComponentConfiguration extends BaseConfiguration {
  final CardConfiguration cardConfiguration;
  final AnalyticsOptions analyticsOptions;

  CardComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required super.amount,
    required super.shopperLocale,
    CardConfiguration? cardConfiguration,
    AnalyticsOptions? analyticsOptions,
  })  : cardConfiguration = cardConfiguration ?? const CardConfiguration(),
        analyticsOptions = analyticsOptions ?? AnalyticsOptions(enabled: true);
}
