import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';

class AdyenCheckoutResultApi implements CheckoutResultFlutterInterface {
  var sessionDropInResultStream = StreamController<SessionDropInResultModel>();

  @override
  void onSessionDropInResult(SessionDropInResultModel sessionDropInResult) {
    sessionDropInResultStream.sink.add(sessionDropInResult);
  }
}
