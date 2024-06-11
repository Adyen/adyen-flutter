import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/base_configuration.dart';

final class ApplePayComponentConfiguration extends BaseConfiguration {
  final ApplePayConfiguration applePayConfiguration;

  ApplePayComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required this.applePayConfiguration,
    super.amount,
    super.shopperLocale,
    super.analyticsOptions,
  });
}
