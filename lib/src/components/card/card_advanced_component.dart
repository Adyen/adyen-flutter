import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/card/base_card_component.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';

class CardAdvancedComponent extends BaseCardComponent {
  final AdvancedCheckout advancedCheckout;
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
  })  : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler(),
        assert(
          advancedCheckout.onAdditionalDetails != null,
          "Please provide the onAdditionalDetails callback for the advanced checkout.",
        );

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
    final PaymentEvent paymentEvent =
        await advancedCheckout.onSubmit(event.data as String);
    final PaymentEventDTO paymentEventDTO =
        paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
    ComponentPlatformApi.instance
        .onPaymentsResult(componentId, paymentEventDTO);
  }

  Future<void> _onAdditionalDetails(ComponentCommunicationModel event) async {
    final PaymentEvent paymentEvent =
        await advancedCheckout.onAdditionalDetails!(event.data as String);
    final PaymentEventDTO paymentEventDTO =
        paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
    ComponentPlatformApi.instance
        .onPaymentsDetailsResult(componentId, paymentEventDTO);
  }
}
