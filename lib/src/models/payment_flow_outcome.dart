sealed class PaymentFlowOutcome {}

class Finished extends PaymentFlowOutcome {
  final String resultCode;

  Finished({required this.resultCode});
}

class Action extends PaymentFlowOutcome {
  final Map<String, dynamic> actionResponse;

  Action({required this.actionResponse});
}

class Error extends PaymentFlowOutcome {
  final String? errorMessage;
  final String? reason;
  final bool dismissDropIn;

  Error({
    this.errorMessage,
    this.reason,
    this.dismissDropIn = false,
  });
}
