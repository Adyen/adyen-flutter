import '../../amount.dart';

class ApplePayShippingMethod {
  final String label;
  final String detail;
  final Amount amount;
  final String identifier;
  final DateTime? startDate;
  final DateTime? endDate;

  const ApplePayShippingMethod({
    required this.label,
    required this.detail,
    required this.amount,
    required this.identifier,
    this.startDate,
    this.endDate,
  });
}
