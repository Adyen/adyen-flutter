import 'dart:async';

import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ComponentResultApi implements ComponentFlutterApi {
  var componentCommunicationStream =
      StreamController<ComponentCommunicationModel>.broadcast();

  @override
  void onComponentCommunication(
      ComponentCommunicationModel componentCommunicationModel) {
    componentCommunicationStream.sink.add(componentCommunicationModel);
  }
}
