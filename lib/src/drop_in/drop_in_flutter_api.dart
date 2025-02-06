import 'dart:async';

import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class DropInFlutterApi implements DropInFlutterInterface {
  StreamController<PlatformCommunicationModel>?
      dropInPlatformCommunicationStream;

  @override
  void onDropInPlatformCommunication(
          PlatformCommunicationModel platformCommunicationModel) =>
      dropInPlatformCommunicationStream?.sink.add(platformCommunicationModel);
}
