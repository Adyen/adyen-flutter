import 'dart:async';

import 'package:adyen_checkout/src/components/apple_pay/apple_pay_callback_registry.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

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
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async =>
      await ApplePayCallbackRegistry.instance
          .handlerFor(componentId)
          ?.onShippingMethodChange(shippingMethod, summaryItems) ??
      ApplePayShippingMethodUpdateDTO(summaryItems: summaryItems);

  @override
  Future<ApplePayShippingContactUpdateDTO> onApplePayShippingContactChange(
    String componentId,
    ApplePayContactDTO contact,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async =>
      await ApplePayCallbackRegistry.instance
          .handlerFor(componentId)
          ?.onShippingContactChange(contact, summaryItems) ??
      ApplePayShippingContactUpdateDTO(summaryItems: summaryItems);

  @override
  Future<ApplePayCouponCodeUpdateDTO> onApplePayCouponCodeChange(
    String componentId,
    String couponCode,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async =>
      await ApplePayCallbackRegistry.instance
          .handlerFor(componentId)
          ?.onCouponCodeChange(couponCode, summaryItems) ??
      ApplePayCouponCodeUpdateDTO(summaryItems: summaryItems);

  @override
  Future<ApplePayAuthorizationResultDTO> onApplePayAuthorize(
    String componentId,
    ApplePayAuthorizedPaymentDTO payment,
  ) async =>
      await ApplePayCallbackRegistry.instance
          .handlerFor(componentId)
          ?.onAuthorize(payment) ??
      ApplePayAuthorizationResultDTO(isSuccess: true);

  void dispose() {
    if (componentCommunicationStream.hasListener == false) {
      _instance = null;
      _componentCommunicationStream.close();
      ComponentFlutterInterface.setUp(null);
    }
  }
}
