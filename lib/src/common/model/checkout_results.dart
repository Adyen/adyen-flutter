import 'action.dart';

class SessionCheckoutResult {
  final String resultCode;
  final String sessionId;
  final String sessionData;

  const SessionCheckoutResult({
    required this.resultCode,
    required this.sessionId,
    required this.sessionData,
  });

  @override
  String toString() =>
      'SessionCheckoutResult(resultCode: $resultCode, sessionId: $sessionId)';
}

class AdvancedCheckoutResult {
  final String resultCode;

  const AdvancedCheckoutResult({required this.resultCode});

  @override
  String toString() => 'AdvancedCheckoutResult(resultCode: $resultCode)';
}

sealed class SubmitResult {
  const SubmitResult._();

  const factory SubmitResult.completion({required String resultCode}) =
      SubmitCompletion;

  const factory SubmitResult.action(Action action) = SubmitAction;

  const factory SubmitResult.retry({String? errorMessage}) = SubmitRetry;
}

final class SubmitCompletion extends SubmitResult {
  final String resultCode;

  const SubmitCompletion({required this.resultCode}) : super._();
}

final class SubmitAction extends SubmitResult {
  final Action action;

  const SubmitAction(this.action) : super._();
}

final class SubmitRetry extends SubmitResult {
  final String? errorMessage;

  const SubmitRetry({this.errorMessage}) : super._();
}

sealed class AdditionalDetailsResult {
  const AdditionalDetailsResult._();

  const factory AdditionalDetailsResult.completion(
      {required String resultCode}) = AdditionalDetailsCompletion;
}

final class AdditionalDetailsCompletion extends AdditionalDetailsResult {
  final String resultCode;

  const AdditionalDetailsCompletion({required this.resultCode}) : super._();
}
