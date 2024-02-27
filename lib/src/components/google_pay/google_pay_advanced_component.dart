import 'dart:async';

import 'package:adyen_checkout/src/common/model/payment_event.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/google_pay/model/google_pay_component_configuration.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/payment_event_handler.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

class GooglePayAdvancedComponent extends StatefulWidget {
  final String googlePayPaymentMethod;
  final GooglePayComponentConfiguration googlePayComponentConfiguration;
  final Future<PaymentEvent> Function(String) onSubmit;
  final Future<PaymentEvent> Function(String) onAdditionalDetails;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final GooglePayButtonTheme? theme;
  final GooglePayButtonType? type;
  final int? cornerRadius;
  final double? width;
  final double? height;
  final Future<void> Function()? onGooglePayUnavailable;
  final Widget? googlePayUnavailableWidget;
  final Widget? loadingIndicator;
  final PaymentEventHandler paymentEventHandler;
  final AdyenLogger adyenLogger;
  final String componentId = "GOOGLE_PAY_ADVANCED_COMPONENT";

  GooglePayAdvancedComponent({
    super.key,
    required this.googlePayPaymentMethod,
    required this.googlePayComponentConfiguration,
    required this.onSubmit,
    required this.onAdditionalDetails,
    required this.onPaymentResult,
    this.theme,
    this.type,
    this.cornerRadius,
    this.width,
    this.height,
    this.onGooglePayUnavailable,
    this.googlePayUnavailableWidget,
    this.loadingIndicator,
    PaymentEventHandler? paymentEventHandler,
    AdyenLogger? adyenLogger,
  })  : paymentEventHandler = paymentEventHandler ?? PaymentEventHandler(),
        adyenLogger = adyenLogger ?? AdyenLogger.instance;

  @override
  State<GooglePayAdvancedComponent> createState() =>
      _GooglePayAdvancedComponentState();
}

class _GooglePayAdvancedComponentState
    extends State<GooglePayAdvancedComponent> {
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider.instance;
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi.instance;
  final ComponentPlatformApi _componentPlatformApi =
      ComponentPlatformApi.instance;
  final ValueNotifier<bool> _isButtonClickable = ValueNotifier<bool>(true);

  @override
  void initState() {
    _componentFlutterApi.componentCommunicationStream.stream
        .where((communicationModel) =>
            communicationModel.componentId == widget.componentId)
        .listen(_handleComponentCommunication);

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
            return _buildGooglePayButton(snapshot);
          } else {
            widget.onGooglePayUnavailable?.call();
            return widget.googlePayUnavailableWidget ?? const SizedBox.shrink();
          }
        }

        return widget.loadingIndicator ?? const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    _componentPlatformApi.onDispose(widget.componentId);
    _componentFlutterApi.dispose();
    _isButtonClickable.dispose();
    super.dispose();
  }

  bool _isGooglePaySupportedOnDevice(
      AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot) {
    return snapshot.data?.instantPaymentType == InstantPaymentType.googlePay &&
        snapshot.data?.isSupported == true;
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
        valueListenable: _isButtonClickable,
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
      cornerRadius:
          widget.cornerRadius ?? RawGooglePayButton.defaultButtonHeight ~/ 2,
      theme: widget.theme ?? GooglePayButtonTheme.dark,
      type: widget.type ?? GooglePayButtonType.buy,
    );
  }

  void onPressed() {
    _isButtonClickable.value = false;
    _componentPlatformApi.onInstantPaymentPressed(
      InstantPaymentType.googlePay,
      widget.componentId,
    );
  }

  Future<InstantPaymentSetupResultDTO> _isGooglePaySupported() async {
    final String versionNumber =
        await _sdkVersionNumberProvider.getSdkVersionNumber();
    final InstantPaymentConfigurationDTO
        instantPaymentComponentConfigurationDTO =
        widget.googlePayComponentConfiguration.toDTO(
      versionNumber,
      InstantPaymentType.googlePay,
    );
    return await _componentPlatformApi.isInstantPaymentSupportedByPlatform(
      instantPaymentComponentConfigurationDTO,
      widget.googlePayPaymentMethod,
      widget.componentId,
    );
  }

  void _handleComponentCommunication(event) {
    _isButtonClickable.value = true;
    switch (event.type) {
      case ComponentCommunicationType.onSubmit:
        _onSubmit(event);
      case ComponentCommunicationType.additionalDetails:
        _onAdditionalDetails(event);
      case ComponentCommunicationType.result:
        _onResult(event);
      case ComponentCommunicationType.error:
        _onError(event);
    }
  }

  Future<void> _onSubmit(ComponentCommunicationModel event) async {
    final PaymentEvent paymentEvent =
        await widget.onSubmit(event.data as String);
    final PaymentEventDTO paymentEventDTO =
        widget.paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
    _componentPlatformApi.onPaymentsResult(
      paymentEventDTO,
      widget.componentId,
    );
  }

  Future<void> _onAdditionalDetails(ComponentCommunicationModel event) async {
    final PaymentEvent paymentEvent =
        await widget.onAdditionalDetails(event.data as String);
    final PaymentEventDTO paymentEventDTO =
        widget.paymentEventHandler.mapToPaymentEventDTO(paymentEvent);
    _componentPlatformApi.onPaymentsDetailsResult(
      paymentEventDTO,
      widget.componentId,
    );
  }

  void _onResult(ComponentCommunicationModel event) {
    String resultCode = event.paymentResult?.resultCode ?? "";
    widget.adyenLogger
        .print("Google pay advanced flow result code: $resultCode");
    widget.onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  void _onError(ComponentCommunicationModel event) {
    String errorMessage = event.data as String;
    widget.onPaymentResult(PaymentError(reason: errorMessage));
  }
}
