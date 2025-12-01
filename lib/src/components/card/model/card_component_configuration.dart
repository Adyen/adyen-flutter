import 'package:adyen_checkout/src/common/model/base_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/card_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/three_ds2_configuration.dart';

final class CardComponentConfiguration extends BaseConfiguration {
  CardComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    super.amount,
    super.shopperLocale,
    super.analyticsOptions,
    this.cardConfiguration = const CardConfiguration(),
    this.threeDS2Configuration = const CardConfiguration(),
  });

  final CardConfiguration cardConfiguration;
  final ThreeDS2Configuration? threeDS2Configuration;

  @override
  String toString() {
    return 'CardComponentConfiguration(cardConfiguration: $cardConfiguration, threeDS2Configuration: $threeDS2Configuration)';
  }
}
