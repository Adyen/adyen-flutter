import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/platform_api.g.dart';

class DropInOutcomeHandler {
  //DropIn results
  static const resultPending = "pending";
  static const resultAuthorized = "authorised";
  static const resultRefused = "refused";
  static const resultError = "error";
  static const resultCanceled = "canceled";

  //Response keys
  static const errorCodeKey = "errorCode";
  static const resultCodeKey = "resultCode";
  static const actionKey = "action";
  static const orderKey = "order";
  static const messageKey = "messageKey";

  DropInOutcome handleResponse(Map<String, dynamic> jsonResponse) {
    if (_isError(jsonResponse)) {
      return Error(
        errorMessage: jsonResponse[messageKey],
        dismissDropIn: true,
      );
    }

    if (_isRefusedInPartialPaymentFlow(jsonResponse)) {
      return Error(
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

  bool _isError(jsonResponse) => jsonResponse.containsKey(errorCodeKey);

  bool _isRefusedInPartialPaymentFlow(jsonResponse) =>
      _isRefused(jsonResponse) && _isNonFullyPaidOrder(jsonResponse);

  bool _isRefused(jsonResponse) => jsonResponse[resultCodeKey]
      .toString()
      .toLowerCase()
      .contains(resultRefused);

  bool _isAction(jsonResponse) => jsonResponse.containsKey(actionKey);

  bool _isNonFullyPaidOrder(jsonResponse) =>
      jsonResponse.containsKey(orderKey) &&
      (getOrderFromResponse(jsonResponse).remainingAmount?.value ?? 0) > 0;

  OrderResponseModel getOrderFromResponse(jsonResponse) {
    return OrderResponseModel(
        pspReference: jsonResponse['pspReference'],
        orderData: jsonResponse['orderData'],
        amount: jsonResponse['amount'] != null
            ? Amount(value: jsonResponse['amount']['value'])
            : null,
        remainingAmount: jsonResponse['remainingAmount'] != null
            ? Amount(value: jsonResponse['remainingAmount']['value'])
            : null);
  }
}
