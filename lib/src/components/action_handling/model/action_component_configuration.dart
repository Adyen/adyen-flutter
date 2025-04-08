import 'package:adyen_checkout/src/common/model/amount.dart';
import 'package:adyen_checkout/src/common/model/analytics_options.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

final class ActionComponentConfiguration {
  final Environment environment;
  final String clientKey;
  final String? shopperLocale;
  final Amount? amount;
  final AnalyticsOptions analyticsOptions;

  ActionComponentConfiguration({
    required this.environment,
    required this.clientKey,
    this.shopperLocale,
    this.amount,
    AnalyticsOptions? analyticsOptions,
  }) : analyticsOptions = analyticsOptions ?? AnalyticsOptions(enabled: true);

  @override
  String toString() {
    return 'ActionComponentConfiguration('
        'environment: $environment, '
        'clientKey: $clientKey, '
        'shopperLocale: $shopperLocale, '
        'amount: $amount, '
        'analyticsOptions: $analyticsOptions)';
  }
}
