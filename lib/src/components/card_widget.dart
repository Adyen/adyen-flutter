import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_result_api.dart';
import 'package:adyen_checkout/src/components/component_result_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class AdyenCardWidget extends StatelessWidget {
  AdyenCardWidget({
    required this.cardComponentConfiguration,
    required this.paymentMethods,
    required this.onSubmit,
    required this.onResult,
    super.key,
  });

  final CardComponentConfiguration cardComponentConfiguration;
  final String paymentMethods;
  final Future<DropInOutcome> Function(String) onSubmit;
  final Future<void> Function(PaymentResult) onResult;
  final ComponentResultApi _resultApi = ComponentResultApi();
  final codec = ComponentFlutterApi.codec;

  @override
  Widget build(BuildContext context) {
    const String viewType = 'cardComponent';
    Map<String, dynamic> creationParams = <String, dynamic>{
      "paymentMethods": paymentMethods,
      "cardComponentConfiguration": cardComponentConfiguration.toDTO(),
    };

    ComponentFlutterApi.setup(_resultApi);

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

    Widget cardView = Container(
      color: Colors.white,
      child: buildCardView(
        viewType,
        creationParams,
      ),
    );

    return StreamBuilder(
        stream: resizeStream.stream.distinct(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          double platformHeight = snapshot.data ?? _determineDefaultHeight();
          print("PlatformHeight: $platformHeight");

          return AnimatedSize(
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              height: platformHeight,
              child: cardView,
            ),
          );
        });
  }

  double _determineDefaultHeight() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 274;
      case TargetPlatform.iOS:
        return 279;
      default:
        throw UnsupportedError('Unsupported platform view');
    }
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
          creationParamsCodec: codec,
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
      creationParamsCodec: codec,
    );
  }
}
