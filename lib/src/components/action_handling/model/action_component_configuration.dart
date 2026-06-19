import 'package:adyen_checkout/src/common/model/amount.dart';
import 'package:adyen_checkout/src/common/model/analytics_options.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/three_ds2/three_ds2_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

final class ActionComponentConfiguration {
  final Environment environment;
  final String clientKey;
  final String? shopperLocale;
  final Amount? amount;
  final AnalyticsOptions analyticsOptions;
  final ThreeDS2Configuration? threeDS2Configuration;

  ActionComponentConfiguration({
    required this.environment,
    required this.clientKey,
    this.shopperLocale,
    this.amount,
    AnalyticsOptions? analyticsOptions,
    this.threeDS2Configuration,
  }) : analyticsOptions = analyticsOptions ?? AnalyticsOptions(enabled: true);

  @override
  String toString() {
    return 'ActionComponentConfiguration('
        'environment: $environment, '
        'clientKey: ****, '
        'shopperLocale: $shopperLocale, '
        'amount: $amount, '
        'analyticsOptions: $analyticsOptions, '
        'threeDS2Configuration: $threeDS2Configuration)';
  }
}
