import 'package:adyen_checkout/adyen_checkout.dart';

class ApplePaySummaryItem {
  final String label;
  final Amount amount;
  final ApplePaySummaryItemType type;

  ApplePaySummaryItem({
    required this.label,
    required this.amount,
    required this.type,
  });
}
