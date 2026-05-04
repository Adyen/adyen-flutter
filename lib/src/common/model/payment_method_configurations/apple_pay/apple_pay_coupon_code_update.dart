import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_payment_error.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';

class ApplePayCouponCodeUpdate {
  final List<ApplePaySummaryItem> summaryItems;
  final List<ApplePayPaymentError>? errors;

  ApplePayCouponCodeUpdate({
    required this.summaryItems,
    this.errors,
  });

  @override
  String toString() {
    return 'ApplePayCouponCodeUpdate('
        'summaryItems: $summaryItems, '
        'errors: $errors)';
  }
}
