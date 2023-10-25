import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class CashAppPayConfiguration {
  final CashAppPayEnvironment cashAppPayEnvironment;
  final String returnUrl;

  const CashAppPayConfiguration(
    this.cashAppPayEnvironment,
    this.returnUrl,
  );
}
