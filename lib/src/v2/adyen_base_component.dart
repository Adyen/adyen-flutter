import 'dart:async';

import 'package:adyen_checkout/src/common/model/card_callbacks/bin_lookup_data.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/platform/android_platform_view.dart';
import 'package:adyen_checkout/src/components/platform/component_container.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/v2/adyen_component_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class AdyenBaseComponent extends StatefulWidget {
  final CheckoutConfigurationDTO checkoutConfiguration;
  final String paymentMethod;
  final String paymentMethodTxVariant;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final double initialViewHeight;
  final bool isStoredPaymentMethod;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final AdyenComponentController? controller;
  final AdyenLogger adyenLogger;
  final void Function(List<BinLookupData>)? onBinLookup;
  final void Function(String)? onBinValue;
  final Stream<ComponentCommunicationModel>? componentCommunicationStream;
  abstract final String componentId;
  abstract final Map<String, dynamic> creationParams;
  abstract final String viewType;

  AdyenBaseComponent({
    super.key,
    required this.checkoutConfiguration,
    required this.paymentMethod,
    required this.paymentMethodTxVariant,
    required this.onPaymentResult,
    required this.initialViewHeight,
    required this.isStoredPaymentMethod,
    this.gestureRecognizers,
    this.controller,
    this.onBinLookup,
    this.onBinValue,
    this.componentCommunicationStream,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger.instance;

  void onResult(ComponentCommunicationModel event) {
    final paymentResult = event.paymentResult;
    if (paymentResult == null) {
      throw Exception("Payment result handling failed");
    }

    switch (paymentResult.type) {
      case PaymentResultEnum.cancelledByUser:
        _onCancelledByUser();
      case PaymentResultEnum.finished:
        onFinished(paymentResult);
      case PaymentResultEnum.error:
        _onError(paymentResult);
    }
  }

  void onFinished(PaymentResultDTO paymentResultDTO);

  void _onError(PaymentResultDTO paymentResultDTO) => onPaymentResult(
        PaymentError(
          reason: paymentResultDTO.reason,
          code: paymentResultDTO.errorCode,
        ),
      );

  void _onCancelledByUser() => onPaymentResult(PaymentCancelledByUser());

  @override
  State<AdyenBaseComponent> createState() => _AdyenBaseComponentState();
}

class _AdyenBaseComponentState extends State<AdyenBaseComponent> {
  final MessageCodec<Object?> _codec =
      ComponentFlutterInterface.pigeonChannelCodec;
  final ComponentPlatformApi _componentPlatformApi =
      ComponentPlatformApi.instance;
  final GlobalKey _componentWidgetKey = GlobalKey();
  late Widget _componentWidget;

  late final AdyenComponentController _effectiveController;
  late StreamSubscription<ComponentCommunicationModel>
      _componentCommunicationSubscription;

  int? previousViewportHeight;
  int? viewportHeight;
  bool _missingControllerError = false;

  @override
  void initState() {
    super.initState();

    _effectiveController = widget.controller ?? AdyenComponentController();
    attachAdyenComponentController(
      _effectiveController,
      () async => _submit(),
    );

    _componentWidget = _buildComponentWidget();
    final stream = widget.componentCommunicationStream ?? onPlatformEvent();
    _componentCommunicationSubscription = stream
        .where((event) => event.componentId == widget.componentId)
        .listen(_onComponentCommunication);
  }

  @override
  Widget build(BuildContext context) {
    if (_missingControllerError) {
      throw StateError(
        'The native component reported a direct (no-input) payment method, '
        'but no AdyenComponentController was supplied. Provide an '
        'AdyenComponentController and trigger payment submission from your own '
        'button using controller.submit().',
      );
    }

    return ComponentContainer(
      componentWidgetKey: _componentWidgetKey,
      initialViewPortHeight: widget.initialViewHeight,
      viewportHeight: viewportHeight,
      componentWidget: _componentWidget,
    );
  }

  @override
  void dispose() {
    _componentCommunicationSubscription.cancel();
    _componentPlatformApi.onDispose(widget.componentId);
    detachAdyenComponentController(_effectiveController);
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  Widget _buildComponentWidget() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidPlatformView(
          key: UniqueKey(),
          viewType: widget.viewType,
          codec: _codec,
          creationParams: widget.creationParams,
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _componentPlatformApi.updateViewHeight,
        );
      case TargetPlatform.iOS:
        return IosPlatformView(
          key: UniqueKey(),
          viewType: widget.viewType,
          codec: _codec,
          creationParams: widget.creationParams,
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _componentPlatformApi.updateViewHeight,
          componentWidgetKey: _componentWidgetKey,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  void _onComponentCommunication(ComponentCommunicationModel event) {
    if (!mounted) return;

    switch (event.type) {
      case ComponentCommunicationType.componentReady:
        _onComponentReady(event);
      case ComponentCommunicationType.resize:
        _resizeViewport(event);
      case ComponentCommunicationType.result:
        widget.onResult(event);
      case ComponentCommunicationType.binLookup:
        _handleOnBinLookup(event, widget.onBinLookup);
      case ComponentCommunicationType.binValue:
        _handleOnBinValue(event, widget.onBinValue);
      default:
        break;
    }
  }

  void _onComponentReady(ComponentCommunicationModel event) {
    final data = event.data;
    if (data is! bool) return;

    if (!data && widget.controller == null) {
      setState(() => _missingControllerError = true);
      return;
    }

    markAdyenComponentControllerReady(_effectiveController, data);

    if (!data) {
      setState(() => viewportHeight = 0);
    }
  }

  Future<void> _submit() async {
    if (mounted && (viewportHeight == null || viewportHeight == 0)) {
      setState(() => viewportHeight = widget.initialViewHeight.ceil());
    }

    await _componentPlatformApi.submitComponent(widget.componentId);
  }

  void _resizeViewport(ComponentCommunicationModel event) {
    final int? newViewportHeight = event.data is int ? event.data as int : null;
    if (newViewportHeight != previousViewportHeight &&
        newViewportHeight != null) {
      setState(() {
        previousViewportHeight = viewportHeight;
        viewportHeight = newViewportHeight;
      });
    }
  }

  void _handleOnBinLookup(
    ComponentCommunicationModel event,
    void Function(List<BinLookupData>)? onBinLookup,
  ) {
    if (onBinLookup == null) {
      return;
    }

    if (event.data case List<Object?> binLookupDataDTOList) {
      onBinLookup(binLookupDataDTOList
          .whereType<BinLookupDataDTO>()
          .toBinLookupDataList());
    }
  }

  void _handleOnBinValue(
    ComponentCommunicationModel event,
    void Function(String)? onBinValue,
  ) {
    if (onBinValue == null) {
      return;
    }

    if (event.data case String binValue) {
      onBinValue(binValue);
    }
  }
}
