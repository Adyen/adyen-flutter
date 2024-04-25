import 'dart:async';
import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/cupertino.dart';

class InstantAdvancedComponent {
  final String componentId = "INSTANT_${UniqueKey().toString()}";
  final AdvancedCheckoutPreview advancedCheckout;
  final AdyenLogger adyenLogger = AdyenLogger.instance;
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider.instance;
  final completer = Completer<PaymentResult>();
  final PaymentEventHandler paymentEventHandler;

  final ComponentPlatformApi componentPlatformApi =
      ComponentPlatformApi.instance;
  late StreamSubscription<ComponentCommunicationModel>
      _componentCommunicationStream;

  InstantAdvancedComponent({
    required this.advancedCheckout,
    PaymentEventHandler? paymentEventHandler,
  }) : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler();

  Future<PaymentResult> start(
    InstantComponentConfiguration instantComponentConfiguration,
    String instantPaymentMethodResponse,
  ) async {
    _componentCommunicationStream = ComponentFlutterApi
        .instance.componentCommunicationStream.stream
        .where((communicationModel) =>
            communicationModel.componentId == componentId)
        .listen(handleComponentCommunication);

    final sdkVersionNumber =
        await _sdkVersionNumberProvider.getSdkVersionNumber();
    final instantPaymentConfigurationDTO = instantComponentConfiguration.toDTO(
      sdkVersionNumber,
      InstantPaymentType.instant,
    );

    ComponentPlatformApi.instance.onInstantPaymentPressed(
      instantPaymentConfigurationDTO,
      instantPaymentMethodResponse,
      componentId,
    );

    return completer.future.then((paymentResult) {
      //TODO clean up
      return paymentResult;
    });
  }

  void handleComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.onSubmit) {
      _onSubmit(event);
    } else if (event.type case ComponentCommunicationType.additionalDetails) {
      _onAdditionalDetails(event);
    } else if (event.type case ComponentCommunicationType.result) {
      onResult(event);
    }
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
          componentId, paymentEventDTO);
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

  void onResult(ComponentCommunicationModel event) {
    switch (event.paymentResult?.type) {
      case PaymentResultEnum.finished:
        onFinished(event.paymentResult);
      case PaymentResultEnum.error:
        _onError(event.paymentResult);
      case PaymentResultEnum.cancelledByUser:
        _onCancelledByUser();
      case null:
        throw Exception("Payment result handling failed");
    }
  }

  void onFinished(PaymentResultDTO? paymentResultDTO) {
    String resultCode = paymentResultDTO?.result?.resultCode ?? "";
    // adyenLogger.print("Google Pay session result code: $resultCode");
    onPaymentResult(PaymentSessionFinished(
      sessionId: paymentResultDTO?.result?.sessionId ?? "",
      sessionData: paymentResultDTO?.result?.sessionData ?? "",
      resultCode: resultCode,
    ));
  }

  void _onError(PaymentResultDTO? paymentResultDTO) =>
      onPaymentResult(PaymentError(reason: paymentResultDTO?.reason));

  void _onCancelledByUser() => onPaymentResult(PaymentCancelledByUser());

  void onPaymentResult(PaymentResult paymentResult) {
    completer.complete(paymentResult);
  }
}
