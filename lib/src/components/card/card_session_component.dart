import 'dart:async';

import 'package:adyen_checkout/src/common/model/payment_result.dart';
import 'package:adyen_checkout/src/components/card/card_component_container.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/platform/android_platform_view.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_transform/stream_transform.dart';

class CardSessionComponent extends StatefulWidget {
  final CardComponentConfigurationDTO cardComponentConfiguration;
  final SessionDTO session;
  final String paymentMethod;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final double initialViewHeight;
  final bool isStoredPaymentMethod;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final AdyenLogger adyenLogger;
  final UniqueKey componentId = UniqueKey();

  CardSessionComponent({
    super.key,
    required this.cardComponentConfiguration,
    required this.session,
    required this.paymentMethod,
    required this.onPaymentResult,
    required this.initialViewHeight,
    required this.isStoredPaymentMethod,
    this.gestureRecognizers,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger.instance;

  @override
  State<CardSessionComponent> createState() => _CardSessionComponentState();
}

class _CardSessionComponentState extends State<CardSessionComponent> {
  final MessageCodec<Object?> _codec =
      ComponentFlutterInterface.pigeonChannelCodec;
  final ComponentPlatformApi _componentPlatformApi =
      ComponentPlatformApi.instance;
  final StreamController<double> _resizeStream = StreamController.broadcast();
  final GlobalKey _cardWidgetKey = GlobalKey();
  late Widget _cardWidget;
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi.instance;

  @override
  void initState() {
    super.initState();

    _cardWidget = _buildCardWidget();
    _componentFlutterApi.componentCommunicationStream.stream
        .where((event) => event.componentId == widget.componentId.toString())
        .listen(_handleComponentCommunication);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _resizeStream.stream
            .debounce(const Duration(milliseconds: 100))
            .distinct(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return CardComponentContainer(
            snapshot: snapshot,
            cardWidgetKey: _cardWidgetKey,
            initialViewHeight: widget.initialViewHeight,
            cardWidget: _cardWidget,
          );
        });
  }

  @override
  void dispose() {
    _componentFlutterApi.dispose();
    _resizeStream.close();
    super.dispose();
  }

  void _handleComponentCommunication(event) async {
    if (event.type case ComponentCommunicationType.result) {
      _onResult(event);
    } else if (event.type case ComponentCommunicationType.error) {
      _onError(event);
    } else if (event.type case ComponentCommunicationType.resize) {
      _onResize(event);
    }
  }

  void _onResult(ComponentCommunicationModel event) {
    String resultCode = event.paymentResult?.resultCode ?? "";
    widget.adyenLogger.print("Card session flow result code: $resultCode");
    widget.onPaymentResult(PaymentAdvancedFinished(resultCode: resultCode));
  }

  void _onError(ComponentCommunicationModel event) {
    String errorMessage = event.data as String;
    widget.onPaymentResult(PaymentError(reason: errorMessage));
  }

  void _onResize(ComponentCommunicationModel event) =>
      _resizeStream.add(event.data as double);

  Widget _buildCardWidget() {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      Constants.sessionKey: widget.session,
      Constants.cardComponentConfigurationKey:
          widget.cardComponentConfiguration,
      Constants.paymentMethodKey: widget.paymentMethod,
      Constants.isStoredPaymentMethodKey: widget.isStoredPaymentMethod,
      Constants.componentIdKey: widget.componentId.toString(),
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidPlatformView(
          key: widget.componentId,
          viewType: Constants.cardComponentSessionKey,
          codec: _codec,
          creationParams: creationParams,
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _componentPlatformApi.updateViewHeight,
        );
      case TargetPlatform.iOS:
        return IosPlatformView(
          key: widget.componentId,
          viewType: Constants.cardComponentSessionKey,
          codec: _codec,
          creationParams: creationParams,
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _componentPlatformApi.updateViewHeight,
          cardWidgetKey: _cardWidgetKey,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}
