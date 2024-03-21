import 'dart:async';

import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ComponentFlutterApi implements ComponentFlutterInterface {
  ComponentFlutterApi._init();

  static ComponentFlutterApi? _instance;

  static ComponentFlutterApi get instance =>
      _instance ??= _initComponentFlutterApi();

  static ComponentFlutterApi _initComponentFlutterApi() {
    ComponentFlutterApi componentFlutterApi = ComponentFlutterApi._init();
    ComponentFlutterInterface.setup(componentFlutterApi);
    _componentCommunicationStream =
        StreamController<ComponentCommunicationModel>.broadcast();
    return componentFlutterApi;
  }

  static late StreamController<ComponentCommunicationModel>
      _componentCommunicationStream;

  StreamController<ComponentCommunicationModel>
      get componentCommunicationStream => _componentCommunicationStream;

  @override
  void onComponentCommunication(
      ComponentCommunicationModel componentCommunicationModel) {
    _componentCommunicationStream.sink.add(componentCommunicationModel);
  }

  void dispose() {
    if (componentCommunicationStream.hasListener == false) {
      _instance = null;
      _componentCommunicationStream.close();
      ComponentFlutterInterface.setup(null);
    }
  }
}
