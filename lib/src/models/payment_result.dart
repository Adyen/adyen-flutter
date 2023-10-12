import 'package:adyen_checkout/adyen_checkout.dart';

sealed class PaymentResult {}

class PaymentAdvancedFlowFinished extends PaymentResult {
  final String resultCode;

  PaymentAdvancedFlowFinished({required this.resultCode});
}

class PaymentSessionFinished extends PaymentResult {
  final String sessionId;
  final String sessionData;
  final String resultCode;
  final OrderResponse? order;

  PaymentSessionFinished({
    required this.sessionId,
    required this.sessionData,
    required this.resultCode,
    this.order,
  });
}

class PaymentCancelledByUser extends PaymentResult {}

class PaymentError extends PaymentResult {
  final String? reason;

  PaymentError({required this.reason});
}
