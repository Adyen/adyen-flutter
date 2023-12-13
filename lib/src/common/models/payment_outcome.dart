sealed class PaymentOutcome {}

class Finished extends PaymentOutcome {
  final String resultCode;

  Finished({required this.resultCode});
}

class Action extends PaymentOutcome {
  final Map<String, dynamic> actionResponse;

  Action({required this.actionResponse});
}

class Error extends PaymentOutcome {
  final String? errorMessage;
  final String? reason;
  final bool dismissDropIn;

  Error({
    required this.errorMessage,
    this.reason = "",
    this.dismissDropIn = false,
  });
}
