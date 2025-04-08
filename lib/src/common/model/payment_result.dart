import 'package:adyen_checkout/src/common/model/order_response.dart';
import 'package:adyen_checkout/src/common/model/result_code.dart';

sealed class PaymentResult {}

class PaymentAdvancedFinished extends PaymentResult {
  final ResultCode resultCode;

  PaymentAdvancedFinished({required this.resultCode});

  @override
  String toString() {
    return 'PaymentAdvancedFinished(resultCode: $resultCode)';
  }
}

class PaymentSessionFinished extends PaymentResult {
  final String sessionId;
  final String sessionData;
  final String sessionResult;
  final ResultCode resultCode;
  final OrderResponse? order;

  PaymentSessionFinished({
    required this.sessionId,
    required this.sessionData,
    required this.sessionResult,
    required this.resultCode,
    this.order,
  });

  @override
  String toString() {
    return 'PaymentSessionFinished('
        'sessionId: $sessionId, '
        'sessionData: $sessionData, '
        'sessionResult: $sessionResult, '
        'resultCode: $resultCode, '
        'order: $order'
        ')';
  }
}

class PaymentCancelledByUser extends PaymentResult {}

class PaymentError extends PaymentResult {
  final String? reason;

  PaymentError({required this.reason});

  @override
  String toString() {
    return 'PaymentError(reason: $reason)';
  }
}
