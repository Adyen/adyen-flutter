sealed class DropInOutcome {}

class Finished extends DropInOutcome {
  final String resultCode;

  Finished({required this.resultCode});
}

class Action extends DropInOutcome {
  final Map<String, dynamic> actionResponse;

  Action({required this.actionResponse});
}

class Error extends DropInOutcome {
  final String? errorMessage;
  final String? reason;
  final bool dismissDropIn;

  Error({
    this.errorMessage,
    this.reason,
    this.dismissDropIn = false,
  });
}
