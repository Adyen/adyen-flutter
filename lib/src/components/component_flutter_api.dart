import 'dart:async';

import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
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
  Future<ApplePayShippingMethodUpdateDTO> onApplePayShippingMethodSelected(
    String componentId,
    ApplePayShippingMethodDTO shippingMethod,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async {
    try {
      final shippingMethodUpdate =
          await _applePayConfiguration?.onShippingMethodSelected?.call(
        shippingMethod.fromDTO(),
        summaryItems.fromDTOs(),
      );
      return shippingMethodUpdate?.toDTO() ??
          ApplePayShippingMethodUpdateDTO(summaryItems: summaryItems);
    } catch (exception) {
      AdyenLogger.instance
          .print('onApplePayShippingMethodSelected failed: $exception');
      return ApplePayShippingMethodUpdateDTO(summaryItems: summaryItems);
    }
  }

  @override
  Future<ApplePayShippingContactUpdateDTO> onApplePayShippingContactSelected(
    String componentId,
    ApplePayContactDTO contact,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async {
    try {
      final shippingContactUpdate =
          await _applePayConfiguration?.onShippingContactSelected?.call(
        contact.fromDTO(),
        summaryItems.fromDTOs(),
      );
      return shippingContactUpdate?.toDTO() ??
          ApplePayShippingContactUpdateDTO(summaryItems: summaryItems);
    } catch (exception) {
      AdyenLogger.instance
          .print('onApplePayShippingContactSelected failed: $exception');
      return ApplePayShippingContactUpdateDTO(summaryItems: summaryItems);
    }
  }

  @override
  Future<ApplePayCouponCodeUpdateDTO> onApplePayCouponCodeChanged(
    String componentId,
    String couponCode,
    List<ApplePaySummaryItemDTO?> summaryItems,
  ) async {
    try {
      final couponCodeUpdate =
          await _applePayConfiguration?.onCouponCodeChanged?.call(
        couponCode,
        summaryItems.fromDTOs(),
      );
      return couponCodeUpdate?.toDTO() ??
          ApplePayCouponCodeUpdateDTO(summaryItems: summaryItems);
    } catch (exception) {
      AdyenLogger.instance
          .print('onApplePayCouponCodeChanged failed: $exception');
      return ApplePayCouponCodeUpdateDTO(summaryItems: summaryItems);
    }
  }

  @override
  Future<ApplePayAuthorizationResultDTO> onApplePayAuthorized(
    String componentId,
    ApplePayAuthorizedPaymentDTO payment,
  ) async {
    try {
      final authorizationResult =
          await _applePayConfiguration?.onAuthorized?.call(payment.fromDTO());
      return authorizationResult?.toDTO() ??
          ApplePayAuthorizationResultDTO(isSuccess: true);
    } catch (exception) {
      AdyenLogger.instance.print('onApplePayAuthorized failed: $exception');
      return ApplePayAuthorizationResultDTO(isSuccess: false);
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
