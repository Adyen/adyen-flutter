sealed class ActionResult {}

class ActionSuccess extends ActionResult {
  final Map<String, dynamic> data;

  ActionSuccess(this.data);
}

class ActionError extends ActionResult {
  final String errorMessage;

  ActionError(this.errorMessage);
}
