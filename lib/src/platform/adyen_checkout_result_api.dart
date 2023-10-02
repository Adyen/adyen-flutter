import 'dart:async';

import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class AdyenCheckoutResultApi implements CheckoutFlutterApi {
  var dropInSessionPlatformCommunicationStream =
      StreamController<PlatformCommunicationModel>();
  var dropInAdvancedFlowPlatformCommunicationStream =
      StreamController<PlatformCommunicationModel>();

  @override
  void onDropInSessionPlatformCommunication(
      PlatformCommunicationModel data) =>
      dropInSessionPlatformCommunicationStream.sink.add(data);

  @override
  void onDropInAdvancedFlowPlatformCommunication(
          PlatformCommunicationModel data) =>
      dropInAdvancedFlowPlatformCommunicationStream.sink.add(data);
}
