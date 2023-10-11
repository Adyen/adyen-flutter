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

class CardWidget extends StatelessWidget {
  CardWidget({
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
    // Pass parameters to the platform side.
    Map<String, dynamic> creationParams = <String, dynamic>{
      "paymentMethods": paymentMethods,
      "clientKey": clientKey,
    };

    CheckoutFlutterApi.setup(_resultApi);

    _resultApi.componentCommunicationStream =
        StreamController<PlatformCommunicationModel>();
    _resultApi.componentCommunicationStream.stream
        .asBroadcastStream()
        .listen((event) async {
      final DropInOutcome result = await onSubmit(event.data!);
      if (result is Finished) {
        print(result.resultCode);
        onResult(PaymentAdvancedFlowFinished(resultCode: result.resultCode));
      }
    });

    return Expanded(
      child: PlatformViewLink(
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
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      ),
    );
  }
}
