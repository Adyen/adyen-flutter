import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/platform/base_platform_view_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';

mixin AdvancedComponentMixin on BasePlatformViewComponent {
  AdvancedCheckout get advancedCheckout;
  PaymentEventHandler get paymentEventHandler;

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.onSubmit) {
      _onSubmit(event);
    } else if (event.type case ComponentCommunicationType.additionalDetails) {
      _onAdditionalDetails(event);
    }
  }

  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    final ResultCode resultCode =
        paymentResultDTO?.result?.toResultCode() ?? ResultCode.unknown;
    adyenLogger.print('Advanced flow result code: $resultCode');
    onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  Future<void> _onSubmit(ComponentCommunicationModel event) async {
    try {
      final data = jsonDecode(event.data as String);
      final PaymentEvent paymentEvent = await advancedCheckout.onSubmit(data);
      final PaymentEventDTO paymentEventDTO =
          paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
      ComponentPlatformApi.instance
          .onPaymentsResult(componentId, paymentEventDTO);
    } catch (exception) {
      _sendErrorToNative(exception.toString());
    }
  }

  Future<void> _onAdditionalDetails(ComponentCommunicationModel event) async {
    try {
      final additionalDetails = jsonDecode(event.data as String);
      final PaymentEvent paymentEvent =
          await advancedCheckout.onAdditionalDetails(additionalDetails);
      final PaymentEventDTO paymentEventDTO =
          paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
      ComponentPlatformApi.instance
          .onPaymentsDetailsResult(componentId, paymentEventDTO);
    } catch (exception) {
      _sendErrorToNative(exception.toString());
    }
  }

  void _sendErrorToNative(String errorMessage) {
    ComponentPlatformApi.instance.onPaymentsResult(
      componentId,
      PaymentEventDTO(
        paymentEventType: PaymentEventType.error,
        error: ErrorDTO(errorMessage: errorMessage),
      ),
    );
  }
}
