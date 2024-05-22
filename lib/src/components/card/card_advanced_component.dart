import 'dart:async';
import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/card/base_card_component.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';

class CardAdvancedComponent extends BaseCardComponent {
  final Checkout advancedCheckout;
  final PaymentEventHandler paymentEventHandler;

  @override
  final String componentId = "CARD_ADVANCED_COMPONENT";

  @override
  String get viewType => Constants.cardComponentAdvancedKey;

  CardAdvancedComponent({
    super.key,
    required super.cardComponentConfiguration,
    required super.paymentMethod,
    required super.onPaymentResult,
    required this.advancedCheckout,
    required super.initialViewHeight,
    required super.isStoredPaymentMethod,
    super.gestureRecognizers,
    super.adyenLogger,
    PaymentEventHandler? paymentEventHandler,
  }) : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler();

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.paymentMethodKey: paymentMethod,
        Constants.cardComponentConfigurationKey: cardComponentConfiguration,
        Constants.isStoredPaymentMethodKey: isStoredPaymentMethod,
        Constants.componentIdKey: componentId,
      };

  @override
  void handleComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.onSubmit) {
      _onSubmit(event);
    } else if (event.type case ComponentCommunicationType.additionalDetails) {
      _onAdditionalDetails(event);
    } else if (event.type case ComponentCommunicationType.result) {
      onResult(event);
    } else if (event.type case ComponentCommunicationType.resize) {
      onResize(event);
    }
  }

  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    String resultCode = paymentResultDTO?.result?.resultCode ?? "";
    adyenLogger.print("Card advanced flow result code: $resultCode");
    onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  Future<void> _onSubmit(ComponentCommunicationModel event) async {
    try {
      final PaymentEvent paymentEvent = await _getOnSubmitPaymentEvent(event);
      final PaymentEventDTO paymentEventDTO =
          paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
      ComponentPlatformApi.instance
          .onPaymentsResult(componentId, paymentEventDTO);
    } catch (exception) {
      ComponentPlatformApi.instance.onPaymentsResult(
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
      final PaymentEvent paymentEvent =
          await _getOnAdditionalDetailsPaymentEvent(event);
      final PaymentEventDTO paymentEventDTO =
          paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
      ComponentPlatformApi.instance
          .onPaymentsDetailsResult(componentId, paymentEventDTO);
    } catch (exception) {
      ComponentPlatformApi.instance.onPaymentsResult(
        componentId,
        PaymentEventDTO(
          paymentEventType: PaymentEventType.error,
          error: ErrorDTO(errorMessage: exception.toString()),
        ),
      );
    }
  }

  Future<PaymentEvent> _getOnSubmitPaymentEvent(
      ComponentCommunicationModel event) async {
    switch (advancedCheckout) {
      case AdvancedCheckout it:
        final data = jsonDecode(event.data as String);
        return await it.onSubmit(data);
      case SessionCheckout():
        throw Exception("Please use the session card component.");
    }
  }

  Future<PaymentEvent> _getOnAdditionalDetailsPaymentEvent(
      ComponentCommunicationModel event) async {
    switch (advancedCheckout) {
      case AdvancedCheckout it:
        final additionalDetails = jsonDecode(event.data as String);
        return await it.onAdditionalDetails(additionalDetails);
      case SessionCheckout():
        throw Exception("Please use the session card component.");
    }
  }
}
