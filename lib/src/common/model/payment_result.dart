import 'package:adyen_checkout/src/common/model/order_response.dart';
import 'package:adyen_checkout/src/common/model/result_code.dart';

sealed class PaymentResult {}

class PaymentAdvancedFinished extends PaymentResult {
  final ResultCode resultCode;

  PaymentAdvancedFinished({required this.resultCode});
}

class PaymentSessionFinished extends PaymentResult {
  final String sessionId;
  final String sessionData;
  final ResultCode resultCode;
  final OrderResponse? order;
  final String? sessionResult;

  PaymentSessionFinished({
    required this.sessionId,
    required this.sessionData,
    required this.resultCode,
    this.order,
    this.sessionResult,
  });
}

class PaymentCancelledByUser extends PaymentResult {}

class PaymentError extends PaymentResult {
  final String? reason;

  PaymentError({required this.reason});
}
