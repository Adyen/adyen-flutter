import 'package:adyen_checkout/src/common/model/amount.dart';
import 'package:adyen_checkout/src/common/model/analytics_options.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

base class BaseConfiguration {
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final Amount? amount;
  final String? shopperLocale;
  final AnalyticsOptions analyticsOptions;

  BaseConfiguration({
    required this.environment,
    required this.clientKey,
    required this.countryCode,
    required this.shopperLocale,
    this.amount,
    AnalyticsOptions? analyticsOptions,
  }) : analyticsOptions = analyticsOptions ?? AnalyticsOptions(enabled: true);
}
