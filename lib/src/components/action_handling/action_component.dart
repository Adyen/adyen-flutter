import 'dart:async';
import 'dart:convert';

import 'package:adyen_checkout/src/components/action_handling/model/action_component_configuration.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';

class ActionComponent {
  final String componentId = "ACTION_COMPONENT";
  late final Completer<Map<String, dynamic>> completer;
  StreamSubscription<ComponentCommunicationModel>? componentCommunicationStream;

  Future<Map<String, dynamic>> handleAction(
    ActionComponentConfiguration actionComponentConfiguration,
    Map<String, dynamic> action,
  ) async {
    final sdkVersionNumber =
        await SdkVersionNumberProvider.instance.getSdkVersionNumber();
    final actionComponentConfigurationDTO =
        actionComponentConfiguration.toDTO(sdkVersionNumber);
    completer = Completer<Map<String, dynamic>>();
    componentCommunicationStream = ComponentFlutterApi
        .instance.componentCommunicationStream.stream
        .where((communicationModel) =>
            communicationModel.componentId == componentId)
        .listen(handleComponentCommunication);
    ComponentPlatformApi.instance.handleAction(
      actionComponentConfigurationDTO,
      componentId,
      action,
    );

    return completer.future.then((paymentResult) async {
      ComponentPlatformApi.instance.onDispose(componentId);
      await componentCommunicationStream?.cancel();
      componentCommunicationStream = null;
      return paymentResult;
    });
  }

  void handleComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.result) {
      final String data = event.data as String;
      final Map<String, dynamic> decodedData = jsonDecode(data);
      completer.complete(decodedData);
    }
  }
}
