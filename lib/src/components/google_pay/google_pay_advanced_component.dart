import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/google_pay/base_google_pay_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';

class GooglePayAdvancedComponent extends BaseGooglePayComponent {
  final AdvancedCheckout advancedCheckout;
  final PaymentEventHandler paymentEventHandler;
  @override
  final String componentId = "GOOGLE_PAY_ADVANCED_COMPONENT";

  GooglePayAdvancedComponent({
    super.key,
    required super.googlePayPaymentMethod,
    required super.googlePayComponentConfiguration,
    required super.onPaymentResult,
    required this.advancedCheckout,
    required super.theme,
    required super.type,
    required super.cornerRadius,
    required super.width,
    required super.height,
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
      onLoading();
    } else if (event.type case ComponentCommunicationType.result) {
      onResult(event);
    }
  }

  @override
  void onFinished(PaymentResultDTO? paymentResultDTO) {
    String resultCode = paymentResultDTO?.result?.resultCode ?? "";
    adyenLogger.print("Google Pay result code: $resultCode");
    onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  Future<void> _onSubmit(ComponentCommunicationModel event) async {
    final PaymentEvent paymentEvent =
        await advancedCheckout.onSubmit(event.data as String);
    final PaymentEventDTO paymentEventDTO =
        paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
    componentPlatformApi.onPaymentsResult(componentId, paymentEventDTO);
  }

  Future<void> _onAdditionalDetails(ComponentCommunicationModel event) async {
    final PaymentEvent paymentEvent =
        await advancedCheckout.onAdditionalDetails(event.data as String);
    final PaymentEventDTO paymentEventDTO =
        paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
    componentPlatformApi.onPaymentsDetailsResult(componentId, paymentEventDTO);
  }
}
