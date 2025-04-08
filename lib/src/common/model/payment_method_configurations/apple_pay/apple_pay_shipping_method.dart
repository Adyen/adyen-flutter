import 'package:adyen_checkout/adyen_checkout.dart';

class ApplePayShippingMethod {
  final String label;
  final String detail;
  final Amount amount;
  final String identifier;
  final DateTime? startDate;
  final DateTime? endDate;

  ApplePayShippingMethod({
    required this.label,
    required this.detail,
    required this.amount,
    required this.identifier,
    this.startDate,
    this.endDate,
  });

  @override
  String toString() {
    return 'ApplePayShippingMethod('
        'label: $label, '
        'detail: $detail, '
        'amount: $amount, '
        'identifier: $identifier, '
        'startDate: $startDate, '
        'endDate: $endDate'
        ')';
  }
}
