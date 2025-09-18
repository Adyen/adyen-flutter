import 'package:adyen_checkout/src/common/model/base_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/card_configuration.dart';

final class CardComponentConfiguration extends BaseConfiguration {
  CardComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    super.amount,
    super.shopperLocale,
    super.analyticsOptions,
    this.cardConfiguration = const CardConfiguration(),
  });

  final CardConfiguration cardConfiguration;

  @override
  String toString() {
    return 'CardComponentConfiguration(cardConfiguration: $cardConfiguration)';
  }
}
