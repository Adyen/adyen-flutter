import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';

class ApplePayShippingMethodUpdate {
  final List<ApplePaySummaryItem> summaryItems;

  ApplePayShippingMethodUpdate({
    required this.summaryItems,
  });

  @override
  String toString() {
    return 'ApplePayShippingMethodUpdate(summaryItems: $summaryItems)';
  }
}
