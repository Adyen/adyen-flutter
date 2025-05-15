sealed class ActionResult {}

class ActionSuccess extends ActionResult {
  final Map<String, dynamic> data;

  ActionSuccess(this.data);

  @override
  String toString() {
    return 'ActionSuccess(data: $data)';
  }
}

class ActionError extends ActionResult {
  final String errorMessage;

  ActionError(this.errorMessage);

  @override
  String toString() {
    return 'ActionError(errorMessage: $errorMessage)';
  }
}
