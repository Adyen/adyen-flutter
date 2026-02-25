import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/toggle_area_gesture_recognizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class IosPlatformView extends StatelessWidget {
  final String viewType;
  final Map<String, dynamic> creationParams;
  final MessageCodec codec;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final Function(int) onPlatformViewCreated;
  final GlobalKey widgetKey;

  const IosPlatformView({
    super.key,
    required this.viewType,
    required this.creationParams,
    required this.codec,
    required this.onPlatformViewCreated,
    required this.widgetKey,
    this.gestureRecognizers,
  });

  @override
  UiKitView build(BuildContext context) {
    return UiKitView(
      viewType: viewType,
      onPlatformViewCreated: onPlatformViewCreated,
      layoutDirection: Directionality.of(context),
      creationParams: creationParams,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      creationParamsCodec: codec,
      gestureRecognizers: _createGestureRecognizers(context),
    );
  }

  Set<Factory<OneSequenceGestureRecognizer>> _createGestureRecognizers(
      BuildContext context) {
    final groupedGestureRecognizers = <Factory<OneSequenceGestureRecognizer>>{};
    gestureRecognizers?.forEach((gestureRecognizer) {
      groupedGestureRecognizers.add(gestureRecognizer);
    });
    _addToggleAreaGestureRecognizerForIOSIfRequired(
      groupedGestureRecognizers,
      context,
    );
    return groupedGestureRecognizers;
  }

  void _addToggleAreaGestureRecognizerForIOSIfRequired(
    Set<Factory<OneSequenceGestureRecognizer>> groupedGestureRecognizers,
    BuildContext context,
  ) {
    final checkoutConfiguration =
        creationParams[Constants.checkoutConfigurationKey]
            as CheckoutConfigurationDTO?;
    if (checkoutConfiguration?.cardConfigurationDTO?.showStorePaymentField == true) {
      groupedGestureRecognizers.addAll({
        Factory<HorizontalDragGestureRecognizer>(
            () => HorizontalDragGestureRecognizer()),
        Factory<ToggleAreaGestureRecognizer>(() => ToggleAreaGestureRecognizer(
            cardWidgetKey: widgetKey,
            textDirection: Directionality.of(context))),
      });
    }
  }
}
