import 'dart:async';
import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/instant/base_instant_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';

class InstantAdvancedComponent extends BaseInstantComponent {
  final AdvancedCheckoutPreview advancedCheckout;
  final PaymentEventHandler paymentEventHandler;

  InstantAdvancedComponent({
    required super.componentId,
    required this.advancedCheckout,
    PaymentEventHandler? paymentEventHandler,
  }) : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler();

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.onSubmit) {
      _onSubmit(event);
    } else if (event.type case ComponentCommunicationType.additionalDetails) {
      _onAdditionalDetails(event);
    } else if (event.type case ComponentCommunicationType.result) {
      onResult(event);
    }
  }

  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    String resultCode = paymentResultDTO?.result?.resultCode ?? "";
    adyenLogger.print("Instant component advanced result code: $resultCode");
    completer.complete(PaymentAdvancedFinished(resultCode: resultCode));
  }

  Future<void> _onSubmit(ComponentCommunicationModel event) async {
    try {
      final String submitData = (event.data as String);
      final Map<String, dynamic> submitDataDecoded = jsonDecode(submitData);
      final PaymentEvent paymentEvent = await advancedCheckout.onSubmit(
        submitDataDecoded[Constants.submitDataKey],
        submitDataDecoded[Constants.submitExtraKey],
      );
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
    try {
      final String additionalData = (event.data as String);
      final Map<String, dynamic> additionalDataDecoded =
          jsonDecode(additionalData);
      final PaymentEvent paymentEvent =
          await advancedCheckout.onAdditionalDetails(additionalDataDecoded);
      final PaymentEventDTO paymentEventDTO =
          paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
      componentPlatformApi.onPaymentsDetailsResult(
        componentId,
        paymentEventDTO,
      );
    } catch (exception) {
      componentPlatformApi.onPaymentsDetailsResult(
        componentId,
        PaymentEventDTO(
          paymentEventType: PaymentEventType.error,
          error: ErrorDTO(errorMessage: exception.toString()),
        ),
      );
    }
  }
}
