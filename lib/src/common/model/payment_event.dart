sealed class PaymentEvent {}

class Finished extends PaymentEvent {
  final String resultCode;

  Finished({required this.resultCode});
}

class Action extends PaymentEvent {
  final Map<String, dynamic> actionResponse;

  Action({required this.actionResponse});
}

class Update extends PaymentEvent {
  final Map<String, dynamic> paymentMethods;
  final Map<String, dynamic> orderResponse;

  Update({
    required this.paymentMethods,
    required this.orderResponse,
  });
}

class Error extends PaymentEvent {
  final String? errorMessage;
  final String? reason;
  final bool dismissDropIn;

  Error({
    required this.errorMessage,
    this.reason = "",
    this.dismissDropIn = false,
  });
}
