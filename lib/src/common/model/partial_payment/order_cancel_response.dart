class OrderCancelResponse {
  final Map<String, dynamic> orderCancelResponseBody;
  Map<String, dynamic>? updatedPaymentMethods;

  OrderCancelResponse({
    required this.orderCancelResponseBody,
    this.updatedPaymentMethods,
  });
}
