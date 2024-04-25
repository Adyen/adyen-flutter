import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/base_configuration.dart';

final class GooglePayComponentConfiguration extends BaseConfiguration {
  final GooglePayConfiguration googlePayConfiguration;

  GooglePayComponentConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required super.amount,
    required this.googlePayConfiguration,
    super.shopperLocale,
    super.analyticsOptions,
  });
}
