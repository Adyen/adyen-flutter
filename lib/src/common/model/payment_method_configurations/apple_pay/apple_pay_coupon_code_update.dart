import 'apple_pay_payment_error.dart';
import 'apple_pay_shipping_method.dart';
import 'apple_pay_summary_item.dart';

class ApplePayCouponCodeUpdate {
  final List<ApplePaySummaryItem> summaryItems;
  final List<ApplePayShippingMethod>? shippingMethods;
  final List<ApplePayPaymentError>? errors;

  const ApplePayCouponCodeUpdate({
    required this.summaryItems,
    this.shippingMethods,
    this.errors,
  });
}
