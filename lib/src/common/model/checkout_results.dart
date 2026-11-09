class CheckoutResult {
  final String resultCode;
  final String sessionId;
  final String sessionResult;

  const CheckoutResult({
    required this.resultCode,
    required this.sessionId,
    required this.sessionResult,
  });

  @override
  String toString() =>
      'CheckoutResult(resultCode: $resultCode, sessionId: $sessionId)';
}

class AdvancedCheckoutResult {
  final String resultCode;

  const AdvancedCheckoutResult({required this.resultCode});

  @override
  String toString() => 'AdvancedCheckoutResult(resultCode: $resultCode)';
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
