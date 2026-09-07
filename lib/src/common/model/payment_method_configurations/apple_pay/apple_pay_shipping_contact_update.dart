import 'apple_pay_payment_error.dart';
import 'apple_pay_shipping_method.dart';
import 'apple_pay_summary_item.dart';

class ApplePayShippingContactUpdate {
  final List<ApplePaySummaryItem> summaryItems;
  final List<ApplePayShippingMethod>? shippingMethods;
  final List<ApplePayPaymentError>? errors;

  const ApplePayShippingContactUpdate({
    required this.summaryItems,
    this.shippingMethods,
    this.errors,
  });
}
