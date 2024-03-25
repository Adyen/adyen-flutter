import 'dart:convert';

import 'package:adyen_checkout/src/common/model/payment_event.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/apple_pay/base_apple_pay_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';

class ApplePayAdvancedComponent extends BaseApplePayComponent {
  final Future<PaymentEvent> Function(String) onSubmit;
  final Future<PaymentEvent> Function(String) onAdditionalDetails;
  final PaymentEventHandler paymentEventHandler;

  @override
  final String componentId = "APPLE_PAY_ADVANCED_COMPONENT";

  ApplePayAdvancedComponent({
    super.key,
    required super.applePayPaymentMethod,
    required super.applePayComponentConfiguration,
    required super.onPaymentResult,
    required this.onSubmit,
    required this.onAdditionalDetails,
    required super.style,
    required super.type,
    required super.width,
    required super.height,
    super.cornerRadius,
    super.loadingIndicator,
    super.onUnavailable,
    super.unavailableWidget,
    PaymentEventHandler? paymentEventHandler,
    AdyenLogger? adyenLogger,
  }) : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler();

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {
    isButtonClickable.value = true;
    if (event.type case ComponentCommunicationType.onSubmit) {
      _onSubmit(event);
    } else if (event.type case ComponentCommunicationType.additionalDetails) {
      _onAdditionalDetails(event);
    } else if (event.type case ComponentCommunicationType.loading) {
      _onLoading();
    } else if (event.type case ComponentCommunicationType.result) {
      onResult(event);
    }
  }

  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    String resultCode = paymentResultDTO?.result?.resultCode ?? "";
    adyenLogger.print("Apple Pay advanced flow result code: $resultCode");
    onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  Future<void> _onSubmit(ComponentCommunicationModel event) async {
    try {
      final paymentComponentJson = event.data as Map<dynamic, dynamic>;
      final PaymentEvent paymentEvent =
          await onSubmit(jsonEncode(paymentComponentJson));
      final PaymentEventDTO paymentEventDTO =
          paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
      componentPlatformApi.onPaymentsResult(componentId, paymentEventDTO);
    } catch (exception) {
      componentPlatformApi.onPaymentsResult(
        componentId,
        PaymentEventDTO(
          paymentEventType: PaymentEventType.error,
          error: ErrorDTO(errorMessage: exception.toString()),
        ),
      );
    }
  }

  Future<void> _onAdditionalDetails(ComponentCommunicationModel event) async {
    final PaymentEvent paymentEvent =
        await onAdditionalDetails(event.data as String);
    final PaymentEventDTO paymentEventDTO =
        paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
    componentPlatformApi.onPaymentsDetailsResult(componentId, paymentEventDTO);
  }

  void _onLoading() => isLoading.value = true;
}
