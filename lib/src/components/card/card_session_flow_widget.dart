import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/adyen_component_api.dart';
import 'package:adyen_checkout/src/components/component_result_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';
import 'package:adyen_checkout/src/utils/payment_flow_outcome_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class CardSessionFlowWidget extends StatefulWidget {
  const CardSessionFlowWidget({
    required this.cardComponentConfiguration,
    required this.sessionResponse,
    required this.onPaymentResult,
    required this.initialHeight,
    super.key,
  });

  final CardComponentConfiguration cardComponentConfiguration;
  final String sessionResponse;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final double initialHeight;

  @override
  State<CardSessionFlowWidget> createState() => _CardSessionFlowWidgetState();
}

class _CardSessionFlowWidgetState extends State<CardSessionFlowWidget> {
  final MessageCodec<Object?> _codec = ComponentFlutterApi.codec;
  final AdyenComponentApi _adyenComponentApi = AdyenComponentApi();
  final ComponentResultApi _resultApi = ComponentResultApi();
  final PaymentFlowOutcomeHandler _paymentFlowOutcomeHandler =
      PaymentFlowOutcomeHandler();
  late StreamController<double> _resizeStream;
  late Widget _cardView;

  @override
  void initState() {
    super.initState();

    _resizeStream = StreamController<double>.broadcast();
    _resultApi.componentCommunicationStream =
        StreamController<ComponentCommunicationModel>.broadcast();
    ComponentFlutterApi.setup(_resultApi);
    _cardView = buildCardView();
    _resultApi.componentCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      // switch (event.type) {
      //
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        initialData: widget.initialHeight,
        stream: _resizeStream.stream.distinct(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          double platformHeight = snapshot.data;
          print("PlatformHeight: $platformHeight");
          return SizedBox(
            height: platformHeight,
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

  Widget buildCardView() {
    const String viewType = 'cardComponentSessionFlow';
    final Map<String, dynamic> creationParams = <String, dynamic>{
      "sessionResponse": widget.sessionResponse,
      "cardComponentConfiguration": widget.cardComponentConfiguration.toDTO(),
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return buildAndroidCardView(viewType, creationParams);
      case TargetPlatform.iOS:
        return buildIosCardView(viewType, creationParams);
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  Widget buildAndroidCardView(
      String viewType, Map<String, dynamic> creationParams) {
    SurfaceAndroidViewController surfaceAndroidViewController;

    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        surfaceAndroidViewController =
            PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: _codec,
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..create();

        return surfaceAndroidViewController;
      },
    );
  }

  Widget buildIosCardView(
      String viewType, Map<String, dynamic> creationParams) {
    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      creationParamsCodec: _codec,
    );
  }
}
