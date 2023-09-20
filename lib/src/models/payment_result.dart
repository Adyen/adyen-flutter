import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class PaymentResult {
  final PaymentResultEnum type;
  final String? reason;
  final PaymentResultModel? result;

  PaymentResult(
    this.type,
    this.reason,
    this.result,
  );
}

class PaymentResultModel {
  final String? sessionId;
  final String? sessionData;
  final String? resultCode;
  final OrderResponseDTO? order;

  PaymentResultModel(
    this.sessionId,
    this.sessionData,
    this.resultCode,
    this.order,
  );
}
