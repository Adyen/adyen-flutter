import 'dart:async';

import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/apple_pay/model/apple_pay_component_configuration.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

abstract class BaseApplePayComponent extends StatefulWidget {
  final String applePayPaymentMethod;
  final ApplePayComponentConfiguration applePayComponentConfiguration;
  final Function(PaymentResult) onPaymentResult;
  final ApplePayButtonStyle style;
  final ApplePayButtonType type;
  final double? cornerRadius;
  final double width;
  final double height;
  final Function()? onUnavailable;
  final Widget? unavailableWidget;
  final Widget? loadingIndicator;
  abstract final String componentId;
  final ValueNotifier<bool> isButtonClickable = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider.instance;
  final ComponentFlutterApi componentFlutterApi = ComponentFlutterApi.instance;
  final ComponentPlatformApi componentPlatformApi =
      ComponentPlatformApi.instance;
  final AdyenLogger adyenLogger;

  BaseApplePayComponent({
    super.key,
    required this.applePayPaymentMethod,
    required this.applePayComponentConfiguration,
    required this.onPaymentResult,
    required this.style,
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

  @override
  State<BaseApplePayComponent> createState() => _BaseApplePayComponentState();
}

class _BaseApplePayComponentState extends State<BaseApplePayComponent> {
  @override
  void initState() {
    widget.componentFlutterApi.componentCommunicationStream.stream
        .where((communicationModel) =>
            communicationModel.componentId == widget.componentId)
        .listen(widget.handleComponentCommunication);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _isApplePaySupported(),
      builder: (
        BuildContext context,
        AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_isApplePaySupportedOnDevice(snapshot)) {
            return _buildApplePayOrLoadingContainer(snapshot);
          } else {
            widget.adyenLogger
                .print("Apple pay is not available on this device.");
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
    widget.componentPlatformApi.onDispose(widget.componentId);
    widget.componentFlutterApi.dispose();
    widget.isButtonClickable.dispose();
    widget.isLoading.dispose();
    super.dispose();
  }

  bool _isApplePaySupportedOnDevice(
      AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot) {
    return snapshot.data?.instantPaymentType == InstantPaymentType.applePay &&
        snapshot.data?.isSupported == true;
  }

  Widget _buildApplePayOrLoadingContainer(
      AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot) {
    return ValueListenableBuilder(
      valueListenable: widget.isLoading,
      builder: (BuildContext context, value, Widget? child) {
        if (value == true) {
          return widget.loadingIndicator ?? const SizedBox.shrink();
        } else {
          return _buildApplePayButton(snapshot);
        }
      },
    );
  }

  SizedBox _buildApplePayButton(
      AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot) {
    final String allowedPaymentMethods =
        snapshot.data?.resultData.toString() ?? "[]";
    final Widget applePayButton = _buildRawApplePayButton();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ValueListenableBuilder(
        valueListenable: widget.isButtonClickable,
        builder: (BuildContext context, value, Widget? child) {
          return IgnorePointer(
            ignoring: value == false,
            child: applePayButton,
          );
        },
      ),
    );
  }

  RawApplePayButton _buildRawApplePayButton() {
    return RawApplePayButton(
      onPressed: onPressed,
      style: widget.style,
      type: widget.type,
      cornerRadius: widget.cornerRadius,
    );
  }

  void onPressed() {
    widget.isButtonClickable.value = false;
    widget.componentPlatformApi.onInstantPaymentPressed(
      InstantPaymentType.applePay,
      widget.componentId,
    );
  }

  Future<InstantPaymentSetupResultDTO> _isApplePaySupported() async {
    final String versionNumber =
        await widget._sdkVersionNumberProvider.getSdkVersionNumber();
    final InstantPaymentConfigurationDTO
        instantPaymentComponentConfigurationDTO =
        widget.applePayComponentConfiguration.toDTO(
      versionNumber,
      InstantPaymentType.applePay,
    );
    return await widget.componentPlatformApi
        .isInstantPaymentSupportedByPlatform(
      instantPaymentComponentConfigurationDTO,
      widget.applePayPaymentMethod,
      widget.componentId,
    );
  }
}
