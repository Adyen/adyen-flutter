import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class CashAppPayConfiguration {
  final CashAppPayEnvironment cashAppPayEnvironment;
  final String returnUrl;

  CashAppPayConfiguration(
    this.cashAppPayEnvironment,
    this.returnUrl,
  );
}
