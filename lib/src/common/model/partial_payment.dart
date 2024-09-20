class PartialPayment {
  Future<Map<String, dynamic>> Function(Map<String, dynamic> balanceResponse)
      onCheckBalance;
  Future<Map<String, dynamic>> Function() onRequestOrder;
  Future<Map<String, dynamic>> Function(Map<String, dynamic> orderResponse)
      onCancelOrder;

  PartialPayment({
    required this.onCheckBalance,
    required this.onRequestOrder,
    required this.onCancelOrder,
  });
}
