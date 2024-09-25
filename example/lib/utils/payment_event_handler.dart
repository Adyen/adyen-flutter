import 'package:adyen_checkout/adyen_checkout.dart';

class PaymentEventHandler {
  //Response keys
  static const errorCodeKey = "errorCode";
  static const resultCodeKey = "resultCode";
  static const actionKey = "action";
  static const messageKey = "message";
  static const refusalReasonKey = "refusalReason";

  PaymentEvent handleResponse({
    required Map<String, dynamic> jsonResponse,
    Map<String, dynamic> updatedPaymentMethods = const {},
  }) {
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

    if (_isNonFullyPaidOrder(jsonResponse) &&
        updatedPaymentMethods.isNotEmpty) {
      return Update(
        orderResponse: jsonResponse["order"],
        paymentMethods: updatedPaymentMethods,
      );
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

  bool _isNonFullyPaidOrder(jsonResponse) {
    if (jsonResponse.containsKey("order")) {
      final remainingAmount =
          jsonResponse["order"]["remainingAmount"]["value"];
      return remainingAmount > 0;
    } else {
      return false;
    }
  }
}
