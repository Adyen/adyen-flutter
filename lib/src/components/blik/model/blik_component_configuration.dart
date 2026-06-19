import 'package:adyen_checkout/src/common/model/base_configuration.dart';

final class BlikComponentConfiguration extends BaseConfiguration {
  BlikComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    super.amount,
    super.shopperLocale,
    super.analyticsOptions,
  });
}
