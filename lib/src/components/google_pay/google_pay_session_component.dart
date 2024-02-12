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

class GooglePaySessionComponent extends StatefulWidget {
  final String googlePayPaymentMethod;
  final GooglePayComponentConfiguration googlePayComponentConfiguration;
  final void Function(PaymentResult) onPaymentResult;
  final GooglePayButtonTheme? theme;
  final GooglePayButtonType? type;
  final int? cornerRadius;
  final double? width;
  final double? height;
  final void Function()? onSetupError;
  final Widget? errorIndicator;
  final Widget? loadingIndicator;
  final AdyenLogger adyenLogger;
  final UniqueKey componentId = UniqueKey();

  GooglePaySessionComponent({
    super.key,
    required this.googlePayPaymentMethod,
    required this.googlePayComponentConfiguration,
    required this.onPaymentResult,
    this.theme,
    this.type,
    this.cornerRadius,
    this.width,
    this.height,
    this.onSetupError,
    this.errorIndicator,
    this.loadingIndicator,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger.instance;

  @override
  State<GooglePaySessionComponent> createState() =>
      _GooglePaySessionComponentState();
}

class _GooglePaySessionComponentState extends State<GooglePaySessionComponent> {
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider();
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi.instance;
  final ComponentPlatformApi _componentPlatformApi =
      ComponentPlatformApi.instance;
  final ValueNotifier<bool> _isButtonClickable = ValueNotifier<bool>(true);

  @override
  void initState() {
    _componentFlutterApi.componentCommunicationStream.stream
        .where(
            (element) => element.componentId == widget.componentId.toString())
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
            widget.onSetupError?.call();
            return widget.errorIndicator ?? const SizedBox.shrink();
          }
        }

        return widget.loadingIndicator ?? const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    _componentPlatformApi.onDispose();
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
    final PaymentConfiguration paymentConfiguration =
        PaymentConfiguration.fromJsonString(
      '''{
        "provider": "google_pay",
        "data": {
          "apiVersion": 2,
          "apiVersionMinor": 0,
          "allowedPaymentMethods": $allowedPaymentMethods
        }}''',
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ValueListenableBuilder(
        valueListenable: _isButtonClickable,
        builder: (BuildContext context, value, Widget? child) {
          return IgnorePointer(
            ignoring: value == false,
            child: RawGooglePayButton(
              paymentConfiguration: paymentConfiguration,
              onPressed: onPressed,
              cornerRadius: widget.cornerRadius ??
                  RawGooglePayButton.defaultButtonHeight ~/ 2,
              theme: widget.theme ?? GooglePayButtonTheme.dark,
              type: widget.type ?? GooglePayButtonType.buy,
            ),
          );
        },
      ),
    );
  }

  void onPressed() {
    _isButtonClickable.value = false;
    _componentPlatformApi.onInstantPaymentPressed(InstantPaymentType.googlePay);
  }

  Future<InstantPaymentSetupResultDTO> _isGooglePaySupported() async {
    final String versionNumber =
        await _sdkVersionNumberProvider.getSdkVersionNumber();
    final InstantPaymentConfigurationDTO
        instantPaymentComponentConfigurationDTO = widget
            .googlePayComponentConfiguration
            .toInstantPaymentConfigurationDTO(versionNumber);
    return await _componentPlatformApi.isInstantPaymentSupportedByPlatform(
      instantPaymentComponentConfigurationDTO,
      widget.googlePayPaymentMethod,
      widget.componentId.toString(),
    );
  }

  void _handleComponentCommunication(event) async {
    _isButtonClickable.value = true;
    if (event.type case ComponentCommunicationType.result) {
      _onResult(event);
    } else if (event.type case ComponentCommunicationType.error) {
      _onError(event);
    }
  }

  void _onResult(ComponentCommunicationModel event) {
    String resultCode = event.paymentResult?.resultCode ?? "";
    widget.adyenLogger
        .print("Google pay session flow result code: $resultCode");
    widget.onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  void _onError(ComponentCommunicationModel event) {
    String errorMessage = event.data as String;
    widget.onPaymentResult(PaymentError(reason: errorMessage));
  }
}
