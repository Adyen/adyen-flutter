import 'package:adyen_checkout/src/common/model/base_configuration.dart';

final class InstantComponentConfiguration extends BaseConfiguration {
  InstantComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required super.amount,
    super.shopperLocale,
    super.analyticsOptions,
  });
}
