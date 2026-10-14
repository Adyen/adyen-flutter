import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ComponentContainer extends StatelessWidget {
  const ComponentContainer({
    super.key,
    required this.viewportHeight,
    required this.initialViewPortHeight,
    required this.componentWidget,
  });

  static const double _bottomSpacing = 8;
  final double initialViewPortHeight;
  final int? viewportHeight;
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
      case TargetPlatform.iOS:
        return const Center(child: CupertinoActivityIndicator());
      default:
        return const Center(child: SizedBox.shrink());
    }
  }

  double _determineHeight(int? height) {
    if (height == null) return initialViewPortHeight;
    return height == 0 ? 0 : height + _bottomSpacing;
  }
}
