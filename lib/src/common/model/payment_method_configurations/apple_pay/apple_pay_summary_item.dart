import '../../amount.dart';
import 'apple_pay_summary_item_type.dart';

class ApplePaySummaryItem {
  final String label;
  final Amount amount;
  final ApplePaySummaryItemType type;

  const ApplePaySummaryItem({
    required this.label,
    required this.amount,
    required this.type,
  });

  @override
  String toString() =>
      'ApplePaySummaryItem(label: $label, amount: $amount, type: $type)';
}
