import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';

class ApplePayCouponCodeUpdate {
  final List<ApplePaySummaryItem> summaryItems;

  ApplePayCouponCodeUpdate({
    required this.summaryItems,
  });

  @override
  String toString() {
    return 'ApplePayCouponCodeUpdate(summaryItems: $summaryItems)';
  }
}
