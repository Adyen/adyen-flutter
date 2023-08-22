import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';

class AdyenCheckoutResultApi implements CheckoutResultFlutterInterface {
  var sessionDropInResultStream = StreamController<DropInResultModel>();
  var dropInAdvancedFlowPlatformCommunicationStream =
      StreamController<PlatformCommunicationModel>();

  @override
  void onSessionDropInResult(DropInResultModel sessionDropInResult) {
    sessionDropInResultStream.sink.add(sessionDropInResult);
  }

  @override
  void onDropInAdvancedFlowPlatformCommunication(
      PlatformCommunicationModel data) {
    dropInAdvancedFlowPlatformCommunicationStream.sink.add(data);
  }
}
