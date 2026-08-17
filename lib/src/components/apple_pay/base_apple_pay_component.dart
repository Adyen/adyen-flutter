import 'dart:async';

import 'package:adyen_checkout/src/common/model/checkout_configuration.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_button_platform_view.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_callback_handler.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_callback_registry.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:adyen_checkout/src/v2/adyen_component_controller.dart';
import 'package:flutter/material.dart';

/// The default width/height of a native `PKPaymentButton`, matching Apple's
/// Human Interface Guidelines for the Apple Pay button.
const double _minimumApplePayButtonWidth = 100;
const double _minimumApplePayButtonHeight = 30;

abstract class BaseApplePayComponent extends StatefulWidget {
  final String applePayPaymentMethod;
  final CheckoutConfiguration configuration;
  final Function(PaymentResult) onPaymentResult;
  final AdyenComponentController? controller;
  final Function()? onUnavailable;
  final Widget? unavailableWidget;
  final Widget? loadingIndicator;
  abstract final String componentId;
  final ValueNotifier<bool> isButtonClickable = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider.instance;
  final ComponentPlatformApi componentPlatformApi =
      ComponentPlatformApi.instance;
  final AdyenLogger adyenLogger;

  BaseApplePayComponent({
    super.key,
    required this.applePayPaymentMethod,
    required this.configuration,
    required this.onPaymentResult,
    this.controller,
    this.onUnavailable,
    this.unavailableWidget,
    this.loadingIndicator,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger.instance;

  double get _buttonWidth {
    final width = configuration.applePayConfiguration?.buttonWidth ??
        _minimumApplePayButtonWidth;
    return width > _minimumApplePayButtonWidth
        ? width
        : _minimumApplePayButtonWidth;
  }

  double get _buttonHeight {
    final height = configuration.applePayConfiguration?.buttonHeight ??
        _minimumApplePayButtonHeight;
    return height > _minimumApplePayButtonHeight
        ? height
        : _minimumApplePayButtonHeight;
  }

  void handleComponentCommunication(ComponentCommunicationModel event);

  void onFinished(PaymentResultDTO? paymentResultDTO);

  void onResult(ComponentCommunicationModel event) {
    isLoading.value = false;
    final paymentResult = event.paymentResult;
    switch (paymentResult?.type) {
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
  State<BaseApplePayComponent> createState() => _BaseApplePayComponentState();
}

class _BaseApplePayComponentState extends State<BaseApplePayComponent> {
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi.instance;
  late StreamSubscription<ComponentCommunicationModel>
      _componentCommunicationStream;
  late final Future<InstantPaymentSetupResultDTO> _applePaySupportedFuture;
  bool _controllerAttached = false;

  @override
  void initState() {
    super.initState();
    ApplePayCallbackRegistry.instance.register(
      widget.componentId,
      ApplePayCallbackHandler(
          () => widget.configuration.applePayConfiguration!),
    );
    _componentCommunicationStream = _componentFlutterApi
        .componentCommunicationStream.stream
        .where((communicationModel) =>
            communicationModel.componentId == widget.componentId)
        .listen((communicationModel) {
      if (communicationModel.type == ComponentCommunicationType.buttonPressed) {
        onPressed();
      } else {
        widget.handleComponentCommunication(communicationModel);
      }
    });
    _applePaySupportedFuture = _isApplePaySupported();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _applePaySupportedFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (_isApplePaySupportedOnDevice(snapshot)) {
            _attachControllerIfNeeded();
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
    ApplePayCallbackRegistry.instance.unregister(widget.componentId);
    widget.isButtonClickable.dispose();
    widget.isLoading.dispose();
    widget.componentPlatformApi.onDispose(widget.componentId);
    _componentCommunicationStream.cancel();
    if (widget.controller != null && _controllerAttached) {
      detachAdyenComponentController(widget.controller!);
      _controllerAttached = false;
    }
    _componentFlutterApi.dispose();
    super.dispose();
  }

  bool _isApplePaySupportedOnDevice(
      AsyncSnapshot<InstantPaymentSetupResultDTO> snapshot) {
    return snapshot.data?.instantPaymentType == InstantPaymentType.applePay &&
        snapshot.data?.isSupported == true;
  }

  void _attachControllerIfNeeded() {
    final controller = widget.controller;
    if (controller != null && !_controllerAttached) {
      _controllerAttached = true;
      attachAdyenComponentController(controller, () async => onPressed());
      markAdyenComponentControllerReady(controller, true);
    }
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
    final Widget applePayButton = ApplePayButtonPlatformView(
      componentId: widget.componentId,
      style: widget.configuration.applePayConfiguration?.buttonStyle,
    );

    return SizedBox(
      width: widget._buttonWidth,
      height: widget._buttonHeight,
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

  void onPressed() async {
    final instantPaymentConfigurationDTO =
        await createInstantPaymentConfigurationDTO();
    widget.isButtonClickable.value = false;
    widget.componentPlatformApi.onInstantPaymentPressed(
      instantPaymentConfigurationDTO,
      widget.applePayPaymentMethod,
      widget.componentId,
    );
  }

  Future<InstantPaymentSetupResultDTO> _isApplePaySupported() async {
    try {
      final instantPaymentConfigurationDTO =
          await createInstantPaymentConfigurationDTO();
      return await widget.componentPlatformApi
          .isInstantPaymentSupportedByPlatform(
        instantPaymentConfigurationDTO,
        widget.applePayPaymentMethod,
        widget.componentId,
      );
    } catch (exception) {
      return InstantPaymentSetupResultDTO(
        instantPaymentType: InstantPaymentType.applePay,
        isSupported: false,
      );
    }
  }

  Future<InstantPaymentConfigurationDTO>
      createInstantPaymentConfigurationDTO() async {
    final String versionNumber =
        await widget._sdkVersionNumberProvider.getSdkVersionNumber();
    final InstantPaymentConfigurationDTO
        instantPaymentComponentConfigurationDTO =
        widget.configuration.toInstantPaymentConfigurationDTO(
      versionNumber,
      InstantPaymentType.applePay,
    );
    return instantPaymentComponentConfigurationDTO;
  }
}
