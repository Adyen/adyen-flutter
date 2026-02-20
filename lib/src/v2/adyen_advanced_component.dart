import 'dart:async';
import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';
import 'package:adyen_checkout/src/v2/adyen_base_component.dart';

class AdyenAdvancedComponent extends AdyenBaseComponent
    implements AdyenFlutterInterface {
  final AdvancedCheckout advancedCheckout;
  final PaymentEventHandler paymentEventHandler;

  @override
  final String componentId = "ADVANCED_ADYEN_COMPONENT";

  @override
  String get viewType => Constants.adyenAdvancedComponentKey;

  AdyenAdvancedComponent({
    super.key,
    required super.checkoutConfiguration,
    required super.paymentMethod,
    required super.onPaymentResult,
    required this.advancedCheckout,
    required super.initialViewHeight,
    required super.isStoredPaymentMethod,
    super.gestureRecognizers,
    super.adyenLogger,
    super.onBinLookup,
    super.onBinValue,
    PaymentEventHandler? paymentEventHandler,
  }) : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler() {
    AdyenFlutterInterface.setUp(this);
  }

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.paymentMethodKey: paymentMethod,
        Constants.checkoutConfigurationKey: checkoutConfiguration,
        Constants.isStoredPaymentMethodKey: isStoredPaymentMethod,
        Constants.componentIdKey: componentId,
      };

  @override
  Future<CheckoutResultDTO> onSubmit(
      PlatformCommunicationDTO paymentCommunicationModel) async {
    final Map<String, dynamic> data =
        jsonDecode(paymentCommunicationModel.dataJson!);
    final PaymentEvent onSubmitResult = await advancedCheckout.onSubmit(data);
    final CheckoutResultDTO checkoutResultDTO =
        paymentEventHandler.mapToCheckoutResultDTO(onSubmitResult);
    return checkoutResultDTO;
  }

  @override
  Future<CheckoutResultDTO> onAdditionalDetails(
      PlatformCommunicationDTO paymentCommunicationModel) async {
    final Map<String, dynamic> data =
        jsonDecode(paymentCommunicationModel.dataJson!);
    final PaymentEvent onSubmitResult =
        await advancedCheckout.onAdditionalDetails(data);
    final CheckoutResultDTO checkoutResultDTO =
        paymentEventHandler.mapToCheckoutResultDTO(onSubmitResult);
    return checkoutResultDTO;
  }

  @override
  void onFinished(PaymentResultDTO paymentResultDTO) {
    final ResultCode resultCode =
        paymentResultDTO.result?.toResultCode() ?? ResultCode.unknown;
    adyenLogger.print("Component advanced flow result code: $resultCode");
    onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  @override
  void onError(ErrorDTO errorDTO) {
    onPaymentResult(PaymentError(reason: errorDTO.reason));
  }
}
