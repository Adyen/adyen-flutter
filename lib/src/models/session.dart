class Session {
  final String id;
  final String sessionData;
  final String paymentMethodsJson;

  Session({
    required this.id,
    required this.sessionData,
    required this.paymentMethodsJson,
  });
}