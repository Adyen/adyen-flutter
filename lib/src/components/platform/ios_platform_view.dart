import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class IosPlatformView extends StatelessWidget {
  final String viewType;
  final Object creationParams;
  final MessageCodec<Object?> codec;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  const IosPlatformView({
    super.key,
    required this.viewType,
    required this.creationParams,
    required this.codec,
    this.gestureRecognizers,
  });

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: viewType,
      layoutDirection: Directionality.of(context),
      creationParams: creationParams,
      creationParamsCodec: codec,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      gestureRecognizers: gestureRecognizers ?? {},
    );
  }
}
