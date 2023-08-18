import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';

class AdyenCheckoutResultApi implements CheckoutResultFlutterInterface {
  var sessionDropInResultStream = StreamController<SessionDropInResultModel>();
  var dropInAdvancedFlowResultStream =
      StreamController<SessionDropInResultModel>();

  @override
  void onSessionDropInResult(SessionDropInResultModel sessionDropInResult) {
    sessionDropInResultStream.sink.add(sessionDropInResult);
  }

  @override
  void onDropInAdvancedFlowResult(
      SessionDropInResultModel dropInAdvancedFlowResult) {
    dropInAdvancedFlowResultStream.sink.add(dropInAdvancedFlowResult);
  }
}
