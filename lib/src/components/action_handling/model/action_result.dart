sealed class ActionResult {}

class ActionSuccess extends ActionResult {
  final Map<String, dynamic> details;

  ActionSuccess(this.details);
}

class ActionError extends ActionResult {
  final String errorMessage;

  ActionError(this.errorMessage);
}
