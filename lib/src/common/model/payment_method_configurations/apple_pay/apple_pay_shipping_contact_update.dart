import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_payment_error.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_shipping_method.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';

class ApplePayShippingContactUpdate {
  final List<ApplePaySummaryItem> summaryItems;
  final List<ApplePayShippingMethod>? shippingMethods;
  final List<ApplePayPaymentError>? errors;

  ApplePayShippingContactUpdate({
    required this.summaryItems,
    this.shippingMethods,
    this.errors,
  });

  @override
  String toString() {
    return 'ApplePayShippingContactUpdate('
        'summaryItems: $summaryItems, '
        'shippingMethods: $shippingMethods, '
        'errors: $errors)';
  }
}
