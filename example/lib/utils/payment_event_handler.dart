import 'package:adyen_checkout/adyen_checkout.dart';

class PaymentEventHandler {
  //Response keys
  static const errorCodeKey = "errorCode";
  static const resultCodeKey = "resultCode";
  static const actionKey = "action";
  static const orderKey = "order";
  static const messageKey = "message";
  static const refusalReasonKey = "refusalReason";

  PaymentEvent handleResponse(Map<String, dynamic> jsonResponse) {
    if (_isError(jsonResponse)) {
      return Error(
        errorMessage: jsonResponse[messageKey],
        reason: jsonResponse[messageKey] ?? jsonResponse[refusalReasonKey],
        dismissDropIn: true,
      );
    }

    if (_isRefusedInPartialPaymentFlow(jsonResponse)) {
      return Error(
        errorMessage: "Payment is refused",
        reason: "Refused",
        dismissDropIn: true,
      );
    }

    if (_isAction(jsonResponse)) {
      return Action(actionResponse: jsonResponse[actionKey]);
    }

    if (jsonResponse.containsKey(resultCodeKey)) {
      return Finished(resultCode: jsonResponse[resultCodeKey]);
    }

    return Finished(resultCode: "EMPTY");
  }

  bool _isError(jsonResponse) {
    final hasErrorCodeKey = jsonResponse.containsKey(errorCodeKey);
    final hasErrorResultCode = (jsonResponse[resultCodeKey] as String?)
            ?.toUpperCase()
            .contains(ResultCode.error.name.toUpperCase()) ??
        false;
    return hasErrorCodeKey || hasErrorResultCode;
  }

  bool _isRefusedInPartialPaymentFlow(jsonResponse) =>
      _isRefused(jsonResponse) && _isNonFullyPaidOrder(jsonResponse);

  bool _isRefused(jsonResponse) => jsonResponse[resultCodeKey]
      .toString()
      .toUpperCase()
      .contains(ResultCode.refused.name.toUpperCase());

  bool _isAction(jsonResponse) => jsonResponse.containsKey(actionKey);

  bool _isNonFullyPaidOrder(jsonResponse) =>
      jsonResponse.containsKey(orderKey) &&
      (getOrderFromResponse(jsonResponse).remainingAmount?.value ?? 0) > 0;

  OrderResponse getOrderFromResponse(jsonResponse) =>
      OrderResponse.fromJson(jsonResponse);
}
