import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_shipping_method.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';

class ApplePayShippingContactUpdate {
  final List<ApplePaySummaryItem> summaryItems;
  final List<ApplePayShippingMethod>? shippingMethods;

  ApplePayShippingContactUpdate({
    required this.summaryItems,
    this.shippingMethods,
  });

  @override
  String toString() {
    return 'ApplePayShippingContactUpdate('
        'summaryItems: $summaryItems, '
        'shippingMethods: $shippingMethods)';
  }
}
