import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/blik/base_blik_component.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';

class BlikAdvancedComponent extends BaseBlikComponent {
  final Checkout advancedCheckout;
  final PaymentEventHandler paymentEventHandler;

  @override
  final String componentId = 'BLIK_ADVANCED_COMPONENT';

  @override
  String get viewType => Constants.blikComponentAdvancedKey;

  BlikAdvancedComponent({
    super.key,
    required super.blikComponentConfiguration,
    required super.paymentMethod,
    required super.onPaymentResult,
    required this.advancedCheckout,
    required super.initialViewHeight,
    super.adyenLogger,
    PaymentEventHandler? paymentEventHandler,
  }) : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler();

  @override
  Map<String, dynamic> get creationParams => <String, dynamic>{
        Constants.paymentMethodKey: paymentMethod,
        Constants.blikComponentConfigurationKey: blikComponentConfiguration,
        Constants.componentIdKey: componentId,
      };

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
    adyenLogger.print('Blik advanced flow result code: $resultCode');
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
        throw UnsupportedError('Please use the session blik component.');
    }
  }

  Future<PaymentEvent> _getOnAdditionalDetailsPaymentEvent(
      ComponentCommunicationModel event) async {
    switch (advancedCheckout) {
      case AdvancedCheckout it:
        final additionalDetails = jsonDecode(event.data as String);
        return await it.onAdditionalDetails(additionalDetails);
      case SessionCheckout():
        throw UnsupportedError('Please use the session blik component.');
    }
  }
}
