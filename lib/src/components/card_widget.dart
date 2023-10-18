import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_result_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AdyenCardWidget extends StatelessWidget {
  AdyenCardWidget({
    required this.clientKey,
    required this.paymentMethods,
    required this.onSubmit,
    required this.onResult,
    super.key,
  });

  final String paymentMethods;
  final String clientKey;
  final Future<DropInOutcome> Function(String) onSubmit;
  final Future<void> Function(PaymentResult) onResult;
  final AdyenCheckoutResultApi _resultApi = AdyenCheckoutResultApi();

  @override
  Widget build(BuildContext context) {
    const String viewType = '<platform-view-type>';
    Map<String, dynamic> creationParams = <String, dynamic>{
      "paymentMethods": paymentMethods,
      "clientKey": clientKey,
    };

    CheckoutFlutterApi.setup(_resultApi);

    final resizeStream = StreamController<double>();

    _resultApi.componentCommunicationStream =
        StreamController<ComponentCommunicationModel>();
    _resultApi.componentCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      switch (event.type) {
        case ComponentCommunicationType.resize:
          resizeStream.add(event.data as double);
        case ComponentCommunicationType.paymentComponent:
          final DropInOutcome result = await onSubmit(event.data as String);
          if (result is Finished) {
            print(result.resultCode);
            onResult(
                PaymentAdvancedFlowFinished(resultCode: result.resultCode));
          }
      }
    });

    Widget cardView = buildCardView(
      viewType,
      creationParams,
    );

    return StreamBuilder(
        stream: resizeStream.stream,
        builder: (BuildContext context, AsyncSnapshot<double> snapshot) {
          print("value is: $snapshot");
          return SizedBox(
            height: snapshot.data ?? 500,
            child: cardView,
          );
        });

    // return SizedBox(
    //   height: 500,
    //   child: cardView,
    // );
  }

  Widget buildCardView(String viewType, Map<String, dynamic> creationParams) {
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
    const codec = CheckoutPlatformInterface.codec;

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
        return PlatformViewsService.initSurfaceAndroidView(
          id: params.id,
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: codec,
          onFocus: () {
            params.onFocusChanged(true);
          },
        )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }

  Widget buildIosCardView(
      String viewType, Map<String, dynamic> creationParams) {
    const codec = CheckoutPlatformInterface.codec;

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      creationParamsCodec: codec,
    );
  }
}
