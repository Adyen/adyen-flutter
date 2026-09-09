abstract interface class Service {
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body);

  Future<Map<String, dynamic>> fetchPaymentMethods(Map<String, dynamic> body);

  Future<Map<String, dynamic>> postPayments(Map<String, dynamic> body);

  Future<Map<String, dynamic>> postPaymentsDetails(Map<String, dynamic> body);

  Future<Map<String, dynamic>> postCardDetails(Map<String, dynamic> body);
}
