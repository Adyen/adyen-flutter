class Session {
  final String id;
  final String sessionData;
  final String paymentMethodsJson;
  final String sessionSetupResponse;

  Session({
    required this.id,
    required this.sessionData,
    required this.paymentMethodsJson,
    required this.sessionSetupResponse,
  });
}