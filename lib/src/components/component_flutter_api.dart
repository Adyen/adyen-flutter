import 'dart:async';

import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';

class ComponentFlutterApi implements ComponentFlutterInterface {
  ComponentFlutterApi._init();

  static ComponentFlutterApi? _instance;

  static ComponentFlutterApi get instance =>
      _instance ??= _initComponentFlutterApi();

  static ComponentFlutterApi _initComponentFlutterApi() {
    ComponentFlutterApi componentFlutterApi = ComponentFlutterApi._init();
    ComponentFlutterInterface.setUp(componentFlutterApi);
    _componentCommunicationStream =
        StreamController<ComponentCommunicationModel>.broadcast();
    return componentFlutterApi;
  }

  static late StreamController<ComponentCommunicationModel>
      _componentCommunicationStream;
  static ApplePayConfiguration? _applePayConfiguration;

  StreamController<ComponentCommunicationModel>
      get componentCommunicationStream => _componentCommunicationStream;

  @override
  void onComponentCommunication(
      ComponentCommunicationModel componentCommunicationModel) {
    _componentCommunicationStream.sink.add(componentCommunicationModel);
  }

  @override
  Future<ApplePayShippingMethodUpdateDTO> onApplePayShippingMethodChange(
    String componentId,
    ApplePayShippingMethodDTO shippingMethod,
    List<ApplePaySummaryItemDTO?> currentSummaryItems,
  ) async {
    final fallbackSummaryItems = currentSummaryItems
        .whereType<ApplePaySummaryItemDTO>()
        .map((summaryItem) => summaryItem.fromDTO())
        .toList();
    final callback = _applePayConfiguration?.onShippingMethodChange;
    if (callback == null) {
      return ApplePayShippingMethodUpdateDTO(
        summaryItems: currentSummaryItems,
      );
    }

    try {
      return (await callback(
        shippingMethod.fromDTO(),
        fallbackSummaryItems,
      ))
          .toDTO();
    } catch (_) {
      return ApplePayShippingMethodUpdateDTO(
        summaryItems: currentSummaryItems,
      );
    }
  }

  void registerApplePayConfiguration(
      ApplePayConfiguration applePayConfiguration) {
    _applePayConfiguration = applePayConfiguration;
  }

  void dispose() {
    if (componentCommunicationStream.hasListener == false) {
      _instance = null;
      _applePayConfiguration = null;
      _componentCommunicationStream.close();
      ComponentFlutterInterface.setUp(null);
    }
  }
}
