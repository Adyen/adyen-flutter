import 'dart:async';

import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/card/card_component_container.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/platform/android_platform_view.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class BaseBlikComponent extends StatefulWidget {
  final BlikComponentConfigurationDTO blikComponentConfiguration;
  final String paymentMethod;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final double initialViewHeight;
  final AdyenLogger adyenLogger;
  abstract final String componentId;
  abstract final Map<String, dynamic> creationParams;
  abstract final String viewType;

  BaseBlikComponent({
    super.key,
    required this.blikComponentConfiguration,
    required this.paymentMethod,
    required this.onPaymentResult,
    required this.initialViewHeight,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger.instance;

  void handleComponentCommunication(ComponentCommunicationModel event);

  void onFinished(PaymentResultDTO? paymentResultDTO);

  void onResult(ComponentCommunicationModel event) {
    final paymentResult = event.paymentResult;
    if (paymentResult == null) {
      throw Exception('Payment result handling failed');
    }

    switch (paymentResult.type) {
      case PaymentResultEnum.finished:
        onFinished(event.paymentResult);
      case PaymentResultEnum.error:
        _onError(event.paymentResult);
      case PaymentResultEnum.cancelledByUser:
        _onCancelledByUser();
    }
  }

  void _onError(PaymentResultDTO? paymentResultDTO) =>
      onPaymentResult(PaymentError(reason: paymentResultDTO?.reason));

  void _onCancelledByUser() => onPaymentResult(PaymentCancelledByUser());

  @override
  State<BaseBlikComponent> createState() => _BaseBlikComponentState();
}

class _BaseBlikComponentState extends State<BaseBlikComponent> {
  final MessageCodec<Object?> _codec =
      ComponentFlutterInterface.pigeonChannelCodec;
  final ComponentPlatformApi _componentPlatformApi =
      ComponentPlatformApi.instance;
  final GlobalKey _blikWidgetKey = GlobalKey();
  late Widget _blikWidget;
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi.instance;
  late StreamSubscription<ComponentCommunicationModel>
      _componentCommunicationStream;
  int? previousViewportHeight;
  int? viewportHeight;

  @override
  void initState() {
    _blikWidget = _buildBlikWidget();
    _componentCommunicationStream = _componentFlutterApi
        .componentCommunicationStream.stream
        .where((communicationModel) =>
            communicationModel.componentId == widget.componentId)
        .listen(_onComponentCommunication);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CardComponentContainer(
      cardWidgetKey: _blikWidgetKey,
      initialViewPortHeight: widget.initialViewHeight,
      viewportHeight: viewportHeight,
      cardWidget: _blikWidget,
    );
  }

  @override
  void dispose() {
    _componentCommunicationStream.cancel();
    _componentFlutterApi.dispose();
    super.dispose();
  }

  Widget _buildBlikWidget() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidPlatformView(
          key: UniqueKey(),
          viewType: widget.viewType,
          codec: _codec,
          creationParams: widget.creationParams,
          onPlatformViewCreated: _componentPlatformApi.updateViewHeight,
        );
      case TargetPlatform.iOS:
        return IosPlatformView(
          key: UniqueKey(),
          viewType: widget.viewType,
          codec: _codec,
          creationParams: widget.creationParams,
          onPlatformViewCreated: _componentPlatformApi.updateViewHeight,
          cardWidgetKey: _blikWidgetKey,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  void _onComponentCommunication(ComponentCommunicationModel event) {
    if (event.type case ComponentCommunicationType.resize) {
      _resizeViewport(event);
    } else if (event.type case ComponentCommunicationType.result) {
      widget.onResult(event);
    } else {
      widget.handleComponentCommunication(event);
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
}
