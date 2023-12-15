import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/model/oder_response.dart';

sealed class PaymentResult {}

class PaymentAdvancedFinished extends PaymentResult {
  final String resultCode;

  PaymentAdvancedFinished({required this.resultCode});
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
