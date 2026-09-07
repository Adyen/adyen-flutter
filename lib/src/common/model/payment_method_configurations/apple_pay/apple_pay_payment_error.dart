import 'apple_pay_error_field.dart';
import 'apple_pay_payment_error_type.dart';

class ApplePayPaymentError {
  final ApplePayPaymentErrorType type;
  final ApplePayErrorField? field;
  final String localizedDescription;

  const ApplePayPaymentError({
    required this.type,
    this.field,
    required this.localizedDescription,
  });

  @override
  String toString() => 'ApplePayPaymentError(type: $type, field: $field)';
}
