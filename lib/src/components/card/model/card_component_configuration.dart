import 'package:adyen_checkout/src/common/model/amount.dart';
import 'package:adyen_checkout/src/common/model/base_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/card_configuration.dart';

final class CardComponentConfiguration extends BaseConfiguration {
  final CardConfiguration cardConfiguration;
  final Amount? amount;

  CardComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    this.amount,
    super.shopperLocale,
    super.analyticsOptions,
    CardConfiguration? cardConfiguration,
  }) : cardConfiguration = cardConfiguration ?? const CardConfiguration();
}
