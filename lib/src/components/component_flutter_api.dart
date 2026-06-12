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
  Future<ApplePayShippingMethodUpdateDTO> onApplePaySelectShippingMethod(
    String componentId,
    ApplePayShippingMethodDTO shippingMethod,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async =>
      await ApplePayCallbackRegistry.instance
          .handlerFor(componentId)
          ?.onSelectShippingMethod(shippingMethod, summaryItems) ??
      ApplePayShippingMethodUpdateDTO(summaryItems: summaryItems);

  @override
  Future<ApplePayShippingContactUpdateDTO> onApplePaySelectShippingContact(
    String componentId,
    ApplePayContactDTO contact,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async =>
      await ApplePayCallbackRegistry.instance
          .handlerFor(componentId)
          ?.onSelectShippingContact(contact, summaryItems) ??
      ApplePayShippingContactUpdateDTO(summaryItems: summaryItems);

  @override
  Future<ApplePayCouponCodeUpdateDTO> onApplePayChangeCouponCode(
    String componentId,
    String couponCode,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async =>
      await ApplePayCallbackRegistry.instance
          .handlerFor(componentId)
          ?.onChangeCouponCode(couponCode, summaryItems) ??
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
