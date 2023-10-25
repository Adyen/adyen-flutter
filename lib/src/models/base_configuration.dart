import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/models/amount.dart';

base class BaseConfiguration {
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final Amount amount;
  final String? shopperLocale;

  BaseConfiguration({
    required this.environment,
    required this.clientKey,
    required this.countryCode,
    required this.amount,
    required this.shopperLocale,
  });
}
