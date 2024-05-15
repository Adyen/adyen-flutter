import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/base_configuration.dart';

final class ApplePayComponentConfiguration extends BaseConfiguration {
  final ApplePayConfiguration applePayConfiguration;
  final Amount amount;

  ApplePayComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required this.amount,
    required this.applePayConfiguration,
    super.shopperLocale,
    super.analyticsOptions,
  });
}
