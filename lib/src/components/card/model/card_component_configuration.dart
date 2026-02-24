import 'package:adyen_checkout/src/common/model/base_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/card_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/three_ds2/three_ds2_configuration.dart';

final class CardComponentConfiguration extends BaseConfiguration {
  final CardConfiguration cardConfiguration;
  final ThreeDS2Configuration? threeDS2Configuration;

  CardComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    super.amount,
    super.shopperLocale,
    super.analyticsOptions,
    CardConfiguration? cardConfiguration,
    this.threeDS2Configuration,
  }) : cardConfiguration = cardConfiguration ?? const CardConfiguration();

  @override
  String toString() {
    return 'CardComponentConfiguration(cardConfiguration: $cardConfiguration, threeDS2Configuration: $threeDS2Configuration)';
  }
}
