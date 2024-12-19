class OrderCancelResult {
  final Map<String, dynamic> orderCancelResponseBody;
  Map<String, dynamic>? updatedPaymentMethodsResponseBody;

  OrderCancelResult({
    required this.orderCancelResponseBody,
    this.updatedPaymentMethodsResponseBody,
  });
}
