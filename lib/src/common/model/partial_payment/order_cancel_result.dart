class OrderCancelResult {
  final Map<String, dynamic> orderCancelJson;
  Map<String, dynamic>? updatedPaymentMethodsJson;

  OrderCancelResult({
    required this.orderCancelJson,
    this.updatedPaymentMethodsJson,
  });
}
