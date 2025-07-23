abstract interface class Service {
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body);

  Future<Map<String, dynamic>> fetchPaymentMethods(Map<String, dynamic> body);

  Future<Map<String, dynamic>> postPayments(Map<String, dynamic> body);

  Future<Map<String, dynamic>> postPaymentsDetails(Map<String, dynamic> body);

  Future<bool> deleteStoredPaymentMethod(
    String storedPaymentMethodId,
    Map<String, dynamic> queryParameters,
  );

  Future<Map<String, dynamic>> postPaymentMethodsBalance(
      Map<String, dynamic> body);

  Future<Map<String, dynamic>> postOrders(Map<String, dynamic> body);

  Future<Map<String, dynamic>> postOrdersCancel(Map<String, dynamic> body);

  Future<Map<String, dynamic>> postCardDetails(Map<String, dynamic> body);
}
