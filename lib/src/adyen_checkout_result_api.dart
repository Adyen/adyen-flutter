import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';

class AdyenCheckoutResultApi implements CheckoutResultFlutterInterface {
  var sessionDropInResultStream = StreamController<SessionDropInResultModel>();

  //Advanced flow
  var dropInAdvancedFlowPaymentComponentResultStream =
      StreamController<String>();
  var dropInAdvancedFlowPaymentAdditionalDetailsStream =
      StreamController<String>();
  var dropInAdvancedFlowResultStream =
      StreamController<SessionDropInResultModel>();

  @override
  void onSessionDropInResult(SessionDropInResultModel sessionDropInResult) {
    sessionDropInResultStream.sink.add(sessionDropInResult);
  }

  @override
  void onDropInAdvancedFlowPaymentComponent(String paymentComponent) {
    dropInAdvancedFlowPaymentComponentResultStream.sink.add(paymentComponent);
  }

  @override
  void onDropInAdvancedFlowAdditionalDetails(String additionalDetails) {
    dropInAdvancedFlowPaymentAdditionalDetailsStream.sink
        .add(additionalDetails);
  }

  @override
  void onDropInAdvancedFlowResult(
      SessionDropInResultModel dropInAdvancedFlowResult) {
    dropInAdvancedFlowResultStream.sink.add(dropInAdvancedFlowResult);
  }
}
