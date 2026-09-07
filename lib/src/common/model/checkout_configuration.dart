import 'analytics_configuration.dart';
import 'amount.dart';
import 'environment.dart';
import 'payment_method_configurations/apple_pay/apple_pay_configuration.dart';
import 'payment_method_configurations/card_configuration.dart';
import 'payment_method_configurations/google_pay/google_pay_configuration.dart';

class CheckoutConfiguration {
  final Environment environment;
  final String clientKey;
  final String? countryCode;
  final Amount? amount;
  final AnalyticsConfiguration analyticsConfiguration;
  final bool showSubmitButton;
  final CardConfiguration? cardConfiguration;
  final ApplePayConfiguration? applePayConfiguration;
  final GooglePayConfiguration? googlePayConfiguration;

  const CheckoutConfiguration({
    required this.environment,
    required this.clientKey,
    this.countryCode,
    this.amount,
    this.analyticsConfiguration = const AnalyticsConfiguration(),
    this.showSubmitButton = true,
    this.cardConfiguration,
    this.applePayConfiguration,
    this.googlePayConfiguration,
  });
}
