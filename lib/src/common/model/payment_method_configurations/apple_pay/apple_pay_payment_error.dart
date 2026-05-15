import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_contact_field.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ApplePayPaymentError {
  final ApplePayPaymentErrorType type;
  final ApplePayContactField? field;
  final String localizedDescription;

  ApplePayPaymentError({
    required this.type,
    this.field,
    required this.localizedDescription,
  });

  @override
  String toString() {
    return 'ApplePayPaymentError('
        'type: $type, '
        'field: $field, '
        'localizedDescription: $localizedDescription)';
  }
}
