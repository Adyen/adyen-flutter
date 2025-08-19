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
    Map<String, dynamic> updatedPaymentMethodsJson = const {},
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
      // Mobile Summer 2025 - Assignment 2.2
      // If the /payments response contains an action, it must be mapped to an Action payment event.
      // return Action(actionResponse: jsonResponse[actionKey]);
      return Error(errorMessage: "Action not correctly mapped, please fix.");
    }

    if (_isNonFullyPaidOrder(jsonResponse) &&
        updatedPaymentMethodsJson.isNotEmpty) {
      return Update(
        orderJson: jsonResponse["order"],
        paymentMethodsJson: updatedPaymentMethodsJson,
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
      final remainingAmount = jsonResponse["order"]["remainingAmount"]["value"];
      return remainingAmount > 0;
    } else {
      return false;
    }
  }
}
