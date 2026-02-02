import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/base_configuration.dart';

final class ApplePayComponentConfiguration extends BaseConfiguration {
  ApplePayComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required this.applePayConfiguration,
    super.amount,
    super.shopperLocale,
    super.analyticsOptions,
  });

  final ApplePayConfiguration applePayConfiguration;

  @override
  String toString() {
    return 'ApplePayComponentConfiguration(applePayConfiguration: $applePayConfiguration)';
  }
}
