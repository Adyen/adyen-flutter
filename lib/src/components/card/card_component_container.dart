import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CardComponentContainer extends StatelessWidget {
  const CardComponentContainer({
    super.key,
    required this.viewportHeight,
    required this.cardWidgetKey,
    required this.initialViewPortHeight,
    required this.cardWidget,
  });

  final double bottomSpacing = 8;
  final double initialViewPortHeight;
  final int? viewportHeight;
  final Key cardWidgetKey;
  final Widget cardWidget;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          opacity: viewportHeight != null ? 1 : 0,
          child: SizedBox(
            key: cardWidgetKey,
            height: _determineHeight(viewportHeight),
            child: cardWidget,
          ),
        ),
        if (viewportHeight == null)
          SizedBox(
            height: initialViewPortHeight,
            child: switch (defaultTargetPlatform) {
              TargetPlatform.android =>
                const Center(child: CircularProgressIndicator()),
              _ => const Center(child: SizedBox.shrink()),
            },
          )
      ],
    );
  }

  double _determineHeight(int? height) {
    return height == null ? initialViewPortHeight : height + bottomSpacing;
  }
}
