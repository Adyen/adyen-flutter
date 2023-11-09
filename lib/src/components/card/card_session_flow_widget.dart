import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/component_result_api.dart';
import 'package:adyen_checkout/src/components/platform/android_platform_view.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardSessionFlowWidget extends StatefulWidget {
  const CardSessionFlowWidget({
    required this.cardComponentConfiguration,
    required this.session,
    required this.onPaymentResult,
    required this.initialViewHeight,
    super.key,
  });

  final CardComponentConfigurationDTO cardComponentConfiguration;
  final SessionDTO session;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final double initialViewHeight;

  @override
  State<CardSessionFlowWidget> createState() => _CardSessionFlowWidgetState();
}

class _CardSessionFlowWidgetState extends State<CardSessionFlowWidget> {
  final MessageCodec<Object?> _codec = ComponentFlutterApi.codec;
  final ComponentResultApi _resultApi = ComponentResultApi();
  final StreamController<double> _resizeStream = StreamController.broadcast();
  late Widget _cardView;

  @override
  void initState() {
    super.initState();

    ComponentFlutterApi.setup(_resultApi);
    _cardView = _buildPlatformCardView();
    _resultApi.componentCommunicationStream.stream
        .asBroadcastStream()
        .listen(_handleComponentCommunication);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        initialData: widget.initialViewHeight,
        stream: _resizeStream.stream.distinct(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          double platformViewHeight = snapshot.data;
          return SizedBox(
            height: platformViewHeight,
            child: _cardView,
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
  void _resetCardView() {
    setState(() {
      _cardView = _buildPlatformCardView();
    });
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
    widget.onPaymentResult(PaymentAdvancedFlowFinished(resultCode: resultCode));
  }

  void _onError(ComponentCommunicationModel event) {
    String errorMessage = event.data as String;
    widget.onPaymentResult(PaymentError(reason: errorMessage));
  }

  void _onResize(ComponentCommunicationModel event) =>
      _resizeStream.add(event.data as double);

  Widget _buildPlatformCardView() {
    final Key key = UniqueKey();
    const String viewType = 'cardComponentSessionFlow';
    final Map<String, dynamic> creationParams = <String, dynamic>{
      "session": widget.session,
      "cardComponentConfiguration": widget.cardComponentConfiguration,
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidPlatformView(
          key: key,
          viewType: viewType,
          codec: _codec,
          creationParams: creationParams,
        );
      case TargetPlatform.iOS:
        return IosPlatformView(
          key: key,
          viewType: viewType,
          creationParams: creationParams,
          codec: _codec,
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}
