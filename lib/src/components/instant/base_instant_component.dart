import 'dart:async';

import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/instant/model/instant_component_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';

abstract class BaseInstantComponent {
  final String componentId;
  final AdyenLogger adyenLogger;
  final Completer<PaymentResult> completer = Completer<PaymentResult>();
  final SdkVersionNumberProvider sdkVersionNumberProvider =
      SdkVersionNumberProvider.instance;
  final ComponentPlatformApi componentPlatformApi =
      ComponentPlatformApi.instance;
  StreamSubscription<ComponentCommunicationModel>? componentCommunicationStream;

  BaseInstantComponent({
    required this.componentId,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger.instance;

  void handleComponentCommunication(ComponentCommunicationModel event);

  void onFinished(PaymentResultDTO paymentResultDTO);

  Future<PaymentResult> start(
    InstantComponentConfiguration instantComponentConfiguration,
    String instantPaymentMethodResponse,
  ) async {
    componentCommunicationStream = ComponentFlutterApi
        .instance.componentCommunicationStream.stream
        .where((communicationModel) =>
            communicationModel.componentId == componentId)
        .listen(handleComponentCommunication);

    final sdkVersionNumber =
        await sdkVersionNumberProvider.getSdkVersionNumber();
    final instantPaymentConfigurationDTO = instantComponentConfiguration.toDTO(
      sdkVersionNumber,
      InstantPaymentType.instant,
    );

    componentPlatformApi.onInstantPaymentPressed(
      instantPaymentConfigurationDTO,
      instantPaymentMethodResponse,
      componentId,
    );

    return completer.future.then((paymentResult) async {
      componentPlatformApi.onDispose(componentId);
      await componentCommunicationStream?.cancel();
      componentCommunicationStream = null;
      return paymentResult;
    });
  }

  void onResult(ComponentCommunicationModel event) {
    final paymentResult = event.paymentResult;
    if (paymentResult == null) {
      throw Exception("Payment result handling failed");
    }

    switch (paymentResult.type) {
      case PaymentResultEnum.finished:
        onFinished(paymentResult);
      case PaymentResultEnum.error:
        _onError(paymentResult);
      case PaymentResultEnum.cancelledByUser:
        _onCancelledByUser();
    }
  }

  void _onError(PaymentResultDTO paymentResultDTO) =>
      onPaymentResult(PaymentError(reason: paymentResultDTO.reason));

  void _onCancelledByUser() => onPaymentResult(PaymentCancelledByUser());

  void onPaymentResult(PaymentResult paymentResult) =>
      completer.complete(paymentResult);
}
