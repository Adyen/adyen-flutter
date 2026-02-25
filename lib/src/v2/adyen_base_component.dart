import 'dart:async';

import 'package:adyen_checkout/src/common/model/card_callbacks/bin_lookup_data.dart';
import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/card/adyen_component_container.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/platform/android_platform_view.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
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
  final AdyenLogger adyenLogger;
  final void Function(List<BinLookupData>)? onBinLookup;
  final void Function(String)? onBinValue;
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
    this.onBinLookup,
    this.onBinValue,
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

  void _onError(PaymentResultDTO paymentResultDTO) =>
      onPaymentResult(PaymentError(reason: paymentResultDTO.reason));

  void _onCancelledByUser() => onPaymentResult(PaymentCancelledByUser());

  @override
  State<AdyenBaseComponent> createState() => _AdyenBaseComponentState();
}

class _AdyenBaseComponentState extends State<AdyenBaseComponent> {
  final MessageCodec<Object?> _codec =
      ComponentFlutterInterface.pigeonChannelCodec;
  final ComponentPlatformApi _componentPlatformApi =
      ComponentPlatformApi.instance;
  final GlobalKey _widgetKey = GlobalKey();
  late Widget _componentWidget;
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi.instance;

  int? previousViewportHeight;
  int? viewportHeight;

  @override
  void initState() {
    _componentWidget = _buildComponentWidget();
    onPlatformEvent()
        .where((event) => event.componentId == widget.componentId)
        .listen(onComponentCommunication);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AdyenComponentContainer(
      widgetKey: _widgetKey,
      initialViewPortHeight: widget.initialViewHeight,
      viewportHeight: viewportHeight,
      componentWidget: _componentWidget,
    );
  }

  @override
  void dispose() {
    _componentFlutterApi.dispose();
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
          widgetKey: _widgetKey,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  void onComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.resize) {
      _resizeViewport(event);
    } else if (event.type case ComponentCommunicationType.result) {
      widget.onResult(event);
    } else if (event.type case ComponentCommunicationType.binLookup) {
      _handleOnBinLookup(event, widget.onBinLookup);
    } else if (event.type case ComponentCommunicationType.binValue) {
      _handleOnBinValue(event, widget.onBinValue);
    }
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
