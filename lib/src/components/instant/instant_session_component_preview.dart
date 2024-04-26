import 'dart:async';

import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/instant/model/instant_component_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';

class InstantSessionComponent {
  final String componentId;
  final AdyenLogger adyenLogger = AdyenLogger.instance;
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider.instance;
  final completer = Completer<PaymentResult>();
  late StreamSubscription<ComponentCommunicationModel>
      _componentCommunicationStream;

  InstantSessionComponent(this.componentId);

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
