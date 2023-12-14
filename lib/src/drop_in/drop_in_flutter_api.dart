import 'dart:async';

import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class DropInFlutterApi implements DropInFlutterInterface {
  var dropInSessionPlatformCommunicationStream =
      StreamController<PlatformCommunicationModel>();
  var dropInAdvancedFlowPlatformCommunicationStream =
      StreamController<PlatformCommunicationModel>();

  @override
  void onDropInSessionPlatformCommunication(PlatformCommunicationModel data) =>
      dropInSessionPlatformCommunicationStream.sink.add(data);

  @override
  void onDropInAdvancedPlatformCommunication(
          PlatformCommunicationModel data) =>
      dropInAdvancedFlowPlatformCommunicationStream.sink.add(data);
}
