sealed class PaymentEvent {}

class Finished extends PaymentEvent {
  final String resultCode;

  Finished({required this.resultCode});

  @override
  String toString() {
    return 'Finished(resultCode: $resultCode)';
  }
}

class Action extends PaymentEvent {
  final Map<String, dynamic> actionResponse;

  Action({required this.actionResponse});

  @override
  String toString() {
    return 'Action(actionResponse: $actionResponse)';
  }
}

class Update extends PaymentEvent {
  final Map<String, dynamic> paymentMethodsJson;
  final Map<String, dynamic> orderJson;

  Update({
    required this.paymentMethodsJson,
    required this.orderJson,
  });

  @override
  String toString() {
    return 'Update('
        'paymentMethodsJson: $paymentMethodsJson, '
        'orderJson: $orderJson'
        ')';
  }
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

  @override
  String toString() {
    return 'Error('
        'errorMessage: $errorMessage, '
        'reason: $reason, '
        'dismissDropIn: $dismissDropIn'
        ')';
  }
}
