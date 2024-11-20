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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class BaseCardComponent extends StatefulWidget {
  final CardComponentConfigurationDTO cardComponentConfiguration;
  final String paymentMethod;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final double initialViewHeight;
  final bool isStoredPaymentMethod;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final AdyenLogger adyenLogger;
  abstract final String componentId;
  abstract final Map<String, dynamic> creationParams;
  abstract final String viewType;

  BaseCardComponent({
    super.key,
    required this.cardComponentConfiguration,
    required this.paymentMethod,
    required this.onPaymentResult,
    required this.initialViewHeight,
    required this.isStoredPaymentMethod,
    this.gestureRecognizers,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger.instance;

  void handleComponentCommunication(ComponentCommunicationModel event);

  void onFinished(PaymentResultDTO? paymentResultDTO);

  void onResult(ComponentCommunicationModel event) {
    final paymentResult = event.paymentResult;
    if (paymentResult == null) {
      throw Exception("Payment result handling failed");
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
  State<BaseCardComponent> createState() => _BaseCardComponentState();
}

class _BaseCardComponentState extends State<BaseCardComponent> {
  final MessageCodec<Object?> _codec =
      ComponentFlutterInterface.pigeonChannelCodec;
  final ComponentPlatformApi _componentPlatformApi =
      ComponentPlatformApi.instance;
  final GlobalKey _cardWidgetKey = GlobalKey();
  late Widget _cardWidget;
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi.instance;
  late StreamSubscription<ComponentCommunicationModel>
      _componentCommunicationStream;
  int? previousViewportHeight;
  int? viewportHeight;

  @override
  void initState() {
    _cardWidget = _buildCardWidget();
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
      cardWidgetKey: _cardWidgetKey,
      initialViewPortHeight: widget.initialViewHeight,
      viewportHeight: viewportHeight,
      cardWidget: _cardWidget,
    );
  }

  @override
  void dispose() {
    _componentCommunicationStream.cancel();
    _componentFlutterApi.dispose();
    super.dispose();
  }

  Widget _buildCardWidget() {
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
          cardWidgetKey: _cardWidgetKey,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  void _onComponentCommunication(event) {
    if (event.type case ComponentCommunicationType.resize) {
      final newViewportHeight = event.data as int;
      if (newViewportHeight == previousViewportHeight) {
        return;
      } else {
        setState(() {
          previousViewportHeight = viewportHeight;
          viewportHeight = newViewportHeight;
        });
      }
    } else if (event.type case ComponentCommunicationType.result) {
      widget.onResult(event);
    } else {
      widget.handleComponentCommunication(event);
    }
  }
}
