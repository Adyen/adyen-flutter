import 'dart:async';

import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/google_pay/model/google_pay_component_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

abstract class BaseGooglePayComponent extends StatefulWidget {
  abstract final String componentId;
  final String googlePayPaymentMethod;
  final GooglePayComponentConfiguration googlePayComponentConfiguration;
  final Function(PaymentResult) onPaymentResult;
  final GooglePayButtonTheme theme;
  final GooglePayButtonType type;
  final int cornerRadius;
  final double width;
  final double height;
  final Function()? onUnavailable;
  final Widget? unavailableWidget;
  final Widget? loadingIndicator;
  final ValueNotifier<bool> isButtonClickable = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider.instance;
  final ComponentPlatformApi componentPlatformApi =
      ComponentPlatformApi.instance;
  final AdyenLogger adyenLogger;

  BaseGooglePayComponent({
    super.key,
    required this.googlePayPaymentMethod,
    required this.googlePayComponentConfiguration,
    required this.onPaymentResult,
    required this.theme,
    required this.type,
    required this.cornerRadius,
    required this.width,
    required this.height,
    this.onUnavailable,
    this.unavailableWidget,
    this.loadingIndicator,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger.instance;

  void handleComponentCommunication(ComponentCommunicationModel event);

  void onFinished(PaymentResultDTO? paymentResultDTO);

  void onResult(ComponentCommunicationModel event) {
    isLoading.value = false;
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

  void _onError(PaymentResultDTO? paymentResultDTO) =>
      onPaymentResult(PaymentError(reason: paymentResultDTO?.reason));

  void _onCancelledByUser() => onPaymentResult(PaymentCancelledByUser());

  void onLoading() => isLoading.value = true;

  @override
  State<BaseGooglePayComponent> createState() => _BaseGooglePayComponentState();
}

class _BaseGooglePayComponentState extends State<BaseGooglePayComponent> {
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi.instance;
  late StreamSubscription<ComponentCommunicationModel>
      _componentCommunicationStream;

  @override
  void initState() {
    _componentCommunicationStream = _componentFlutterApi
        .componentCommunicationStream.stream
        .where((communicationModel) =>
            communicationModel.componentId == widget.componentId)
        .listen(widget.handleComponentCommunication);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _isGooglePaySupported(),
      builder: (
        BuildContext context,
        AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_isGooglePaySupportedOnDevice(snapshot)) {
            return _buildGooglePayOrLoadingContainer(snapshot);
          } else {
            widget.adyenLogger
                .print("Google pay is not available on this device.");
            widget.onUnavailable?.call();
            return widget.unavailableWidget ?? const SizedBox.shrink();
          }
        }

        return widget.loadingIndicator ?? const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    widget.isButtonClickable.dispose();
    widget.isLoading.dispose();
    widget.componentPlatformApi.onDispose(widget.componentId);
    _componentCommunicationStream.cancel();
    _componentFlutterApi.dispose();
    super.dispose();
  }

  bool _isGooglePaySupportedOnDevice(
      AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot) {
    return snapshot.data?.instantPaymentType == InstantPaymentType.googlePay &&
        snapshot.data?.isSupported == true;
  }

  Widget _buildGooglePayOrLoadingContainer(
      AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot) {
    return ValueListenableBuilder(
      valueListenable: widget.isLoading,
      builder: (BuildContext context, value, Widget? child) {
        if (value == true) {
          return widget.loadingIndicator ?? const SizedBox.shrink();
        } else {
          return _buildGooglePayButton(snapshot);
        }
      },
    );
  }

  SizedBox _buildGooglePayButton(
      AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot) {
    final String allowedPaymentMethods =
        snapshot.data?.resultData.toString() ?? "[]";
    final Widget googlePayButton =
        _buildRawGooglePayButton(PaymentConfiguration.fromJsonString(
      '''{
        "provider": "google_pay",
        "data": {
          "apiVersion": 2,
          "apiVersionMinor": 0,
          "allowedPaymentMethods": $allowedPaymentMethods
        }}''',
    ));

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ValueListenableBuilder(
        valueListenable: widget.isButtonClickable,
        builder: (BuildContext context, value, Widget? child) {
          return IgnorePointer(
            ignoring: value == false,
            child: googlePayButton,
          );
        },
      ),
    );
  }

  RawGooglePayButton _buildRawGooglePayButton(
      PaymentConfiguration paymentConfiguration) {
    return RawGooglePayButton(
      paymentConfiguration: paymentConfiguration,
      onPressed: onPressed,
      cornerRadius: widget.cornerRadius,
      theme: widget.theme,
      type: widget.type,
    );
  }

  void onPressed() async {
    final instantPaymentConfigurationDTO =
        await createInstantPaymentConfigurationDTO();

    widget.isButtonClickable.value = false;
    widget.componentPlatformApi.onInstantPaymentPressed(
      instantPaymentConfigurationDTO,
      widget.googlePayPaymentMethod,
      widget.componentId,
    );
  }

  Future<InstantPaymentSetupResultDTO> _isGooglePaySupported() async {
    final instantPaymentConfigurationDTO =
        await createInstantPaymentConfigurationDTO();
    return await widget.componentPlatformApi
        .isInstantPaymentSupportedByPlatform(
      instantPaymentConfigurationDTO,
      widget.googlePayPaymentMethod,
      widget.componentId,
    );
  }

  Future<InstantPaymentConfigurationDTO>
      createInstantPaymentConfigurationDTO() async {
    final String versionNumber =
        await widget._sdkVersionNumberProvider.getSdkVersionNumber();
    final InstantPaymentConfigurationDTO
        instantPaymentComponentConfigurationDTO =
        widget.googlePayComponentConfiguration.toDTO(
      versionNumber,
      InstantPaymentType.googlePay,
    );
    return instantPaymentComponentConfigurationDTO;
  }
}
