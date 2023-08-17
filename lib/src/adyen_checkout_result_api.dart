import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';

class AdyenCheckoutResultApi implements CheckoutResultFlutterInterface {
  var sessionDropInResultStream = StreamController<SessionDropInResultModel>();
  var dropInAdvancedFlowPaymentComponentStream = StreamController<String>();

  @override
  void onSessionDropInResult(SessionDropInResultModel sessionDropInResult) {
    sessionDropInResultStream.sink.add(sessionDropInResult);
  }

  @override
  void onPaymentComponentResult(String paymentComponentJson) {
    dropInAdvancedFlowPaymentComponentStream.sink.add(paymentComponentJson);
  }
}
