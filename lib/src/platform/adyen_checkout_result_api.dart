import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';

class AdyenCheckoutResultApi implements CheckoutFlutterApi {
  var dropInSessionResultStream = StreamController<DropInResult>();
  var dropInAdvancedFlowPlatformCommunicationStream =
      StreamController<PlatformCommunicationModel>();

  @override
  void onDropInSessionResult(DropInResult sessionDropInResult) =>
      dropInSessionResultStream.sink.add(sessionDropInResult);

  @override
  void onDropInAdvancedFlowPlatformCommunication(
          PlatformCommunicationModel data) =>
      dropInAdvancedFlowPlatformCommunicationStream.sink.add(data);
}
