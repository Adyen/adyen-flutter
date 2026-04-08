import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

<<<<<<<< HEAD:lib/src/components/card/adyen_component_container.dart
class AdyenComponentContainer extends StatelessWidget {
  const AdyenComponentContainer({
    super.key,
    required this.viewportHeight,
    required this.widgetKey,
========
class ComponentContainer extends StatelessWidget {
  const ComponentContainer({
    super.key,
    required this.viewportHeight,
    required this.componentWidgetKey,
>>>>>>>> main:lib/src/components/platform/component_container.dart
    required this.initialViewPortHeight,
    required this.componentWidget,
  });

  final double bottomSpacing = 8;
  final double initialViewPortHeight;
  final int? viewportHeight;
<<<<<<<< HEAD:lib/src/components/card/adyen_component_container.dart
  final Key widgetKey;
========
  final Key componentWidgetKey;
>>>>>>>> main:lib/src/components/platform/component_container.dart
  final Widget componentWidget;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          opacity: viewportHeight != null ? 1 : 0,
          child: SizedBox(
<<<<<<<< HEAD:lib/src/components/card/adyen_component_container.dart
            key: widgetKey,
========
            key: componentWidgetKey,
>>>>>>>> main:lib/src/components/platform/component_container.dart
            height: _determineHeight(viewportHeight),
            child: componentWidget,
          ),
        ),
        if (viewportHeight == null)
          SizedBox(
            height: initialViewPortHeight,
            child: _buildLoadingWidget(),
          )
      ],
    );
  }

  Widget _buildLoadingWidget() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const Center(child: CircularProgressIndicator());
      default:
        return const Center(child: SizedBox.shrink());
    }
  }

  double _determineHeight(int? height) {
    return height == null ? initialViewPortHeight : height + bottomSpacing;
  }
}
