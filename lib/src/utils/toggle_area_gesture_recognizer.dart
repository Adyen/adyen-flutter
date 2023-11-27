import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class ToggleAreaGestureRecognizer extends OneSequenceGestureRecognizer {
  final GlobalKey cardWidgetKey;
  final TextDirection textDirection;

  ToggleAreaGestureRecognizer({
    required this.cardWidgetKey,
    required this.textDirection,
  });

  @override
  void addPointer(PointerDownEvent event) =>
      startTrackingPointer(event.pointer);

  @override
  void handleEvent(PointerEvent event) {
    final renderBox =
        cardWidgetKey.currentContext?.findRenderObject() as RenderBox;

    switch (event) {
      case PointerDownEvent():
        if (_isPointerOverToggle(event, renderBox)) {
          resolve(GestureDisposition.accepted);
          stopTrackingPointer(event.pointer);
        }

      case PointerMoveEvent():
      case PointerUpEvent():
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => "ToggleAreaGestureRecognizer";

  // ignore: unused_element
  bool _isPointerWithinBottomHalfOfCardView(
    PointerDownEvent event,
    RenderBox renderBox,
  ) {
    final deltaFromTop = renderBox.localToGlobal(Offset.zero).dy;
    final cardWidgetHalfHeight = renderBox.size.height / 2;
    final tapWithinBottomHalfOfCardWidget = event.position.dy - deltaFromTop;
    return tapWithinBottomHalfOfCardWidget > cardWidgetHalfHeight;
  }

  bool _isPointerOverToggle(
    PointerDownEvent event,
    RenderBox renderBox,
  ) {
    const toggleWidth = 80;
    final cardWidgetWidth = renderBox.size.width;
    switch (textDirection) {
      case TextDirection.ltr:
        return event.localPosition.dx > (cardWidgetWidth - toggleWidth);
      case TextDirection.rtl:
        return event.localPosition.dx < toggleWidth;
    }
  }
}
