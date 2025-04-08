import 'package:adyen_checkout/src/common/model/partial_payment/order_cancel_result.dart';

class PartialPayment {
  Future<Map<String, dynamic>> Function({
    required Map<String, dynamic> balanceCheckRequestBody,
  }) onCheckBalance;

  Future<Map<String, dynamic>> Function() onRequestOrder;

  Future<OrderCancelResult> Function({
    required bool shouldUpdatePaymentMethods,
    required Map<String, dynamic> order,
  }) onCancelOrder;

  PartialPayment({
    required this.onCheckBalance,
    required this.onRequestOrder,
    required this.onCancelOrder,
  });

  @override
  String toString() {
    return 'PartialPayment('
        'onCheckBalance: $onCheckBalance, '
        'onRequestOrder: $onRequestOrder, '
        'onCancelOrder: $onCancelOrder'
        ')';
  }
}
