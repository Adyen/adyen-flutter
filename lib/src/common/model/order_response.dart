import 'package:adyen_checkout/src/common/model/amount.dart';

class OrderResponse {
  final String pspReference;
  final String orderData;
  final Amount? amount;
  final Amount? remainingAmount;

  OrderResponse({
    required this.pspReference,
    required this.orderData,
    this.amount,
    this.remainingAmount,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      pspReference: json['pspReference'],
      orderData: json['orderData'],
      amount: json['amount'] != null ? Amount.fromJson(json['amount']) : null,
      remainingAmount: json['remainingAmount'] != null
          ? Amount.fromJson(json['remainingAmount'])
          : null,
    );
  }

  @override
  String toString() {
    return 'OrderResponse('
        'pspReference: $pspReference, '
        'orderData: $orderData, '
        'amount: $amount, '
        'remainingAmount: $remainingAmount'
        ')';
  }
}
