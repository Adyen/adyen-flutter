import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class CashAppPayConfiguration {
  final CashAppPayEnvironment cashAppPayEnvironment;
  final String returnUrl;

  const CashAppPayConfiguration({
    required this.cashAppPayEnvironment,
    required this.returnUrl,
  });

  @override
  String toString() {
    return 'CashAppPayConfiguration('
        'cashAppPayEnvironment: $cashAppPayEnvironment, '
        'returnUrl: $returnUrl)';
  }
}
