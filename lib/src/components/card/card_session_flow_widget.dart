import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/card/card_component_container_widget.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/component_result_api.dart';
import 'package:adyen_checkout/src/components/platform/android_platform_view.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stream_transform/stream_transform.dart';

class CardSessionFlowWidget extends StatefulWidget {
  CardSessionFlowWidget({
    super.key,
    required this.cardComponentConfiguration,
    required this.session,
    required this.onPaymentResult,
    required this.initialViewHeight,
    this.gestureRecognizers,
    AdyenLogger? adyenLogger,
  }) : adyenLogger = adyenLogger ?? AdyenLogger();

  final CardComponentConfigurationDTO cardComponentConfiguration;
  final SessionDTO session;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final double initialViewHeight;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final AdyenLogger adyenLogger;

  @override
  State<CardSessionFlowWidget> createState() => _CardSessionFlowWidgetState();
}

class _CardSessionFlowWidgetState extends State<CardSessionFlowWidget> {
  final MessageCodec<Object?> _codec = ComponentFlutterApi.codec;
  final ComponentResultApi _resultApi = ComponentResultApi();
  final ComponentPlatformApi _componentPlatformApi = ComponentPlatformApi();
  final StreamController<double> _resizeStream = StreamController.broadcast();
  final GlobalKey _cardWidgetKey = GlobalKey();
  late Widget _cardWidget;

  @override
  void initState() {
    super.initState();

    ComponentFlutterApi.setup(_resultApi);
    _cardWidget = _buildCardWidget();
    _resultApi.componentCommunicationStream.stream
        .asBroadcastStream()
        .listen(_handleComponentCommunication);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _resizeStream.stream
            .debounce(const Duration(milliseconds: 100))
            .distinct(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          return AdyenCardComponentContainerWidget(
            snapshot: snapshot,
            cardWidgetKey: _cardWidgetKey,
            initialViewHeight: widget.initialViewHeight,
            cardWidget: _cardWidget,
          );
        });
  }

  @override
  void dispose() {
    _resultApi.componentCommunicationStream.close();
    _resizeStream.close();
    super.dispose();
  }

  // ignore: unused_element
  // void _resetCardView() {
  //   setState(() {
  //     _cardWidget = _buildCardWidget();
  //   });
  // }

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
    widget.onPaymentResult(PaymentAdvancedFlowFinished(resultCode: resultCode));
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
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidPlatformView(
          key: UniqueKey(),
          viewType: Constants.cardComponentSessionFlowKey,
          codec: _codec,
          creationParams: creationParams,
          gestureRecognizers: widget.gestureRecognizers,
          onPlatformViewCreated: _componentPlatformApi.updateViewHeight,
        );
      case TargetPlatform.iOS:
        return IosPlatformView(
          key: UniqueKey(),
          viewType: Constants.cardComponentSessionFlowKey,
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
