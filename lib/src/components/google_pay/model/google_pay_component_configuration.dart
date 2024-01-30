import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/base_configuration.dart';

final class GooglePayComponentConfiguration extends BaseConfiguration {
  final GooglePayConfiguration googlePayConfiguration;
  final AnalyticsOptions analyticsOptions;

  GooglePayComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required super.amount,
    required this.googlePayConfiguration,
    super.shopperLocale,
    AnalyticsOptions? analyticsOptions,
  }) : analyticsOptions = analyticsOptions ?? AnalyticsOptions(enabled: true);
}
