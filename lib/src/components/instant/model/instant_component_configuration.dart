import 'package:adyen_checkout/src/common/model/amount.dart';
import 'package:adyen_checkout/src/common/model/base_configuration.dart';

final class InstantComponentConfiguration extends BaseConfiguration {
  final Amount? amount;

  InstantComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    this.amount,
    super.shopperLocale,
    super.analyticsOptions,
  });
}
