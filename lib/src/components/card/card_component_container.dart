import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CardComponentContainer extends StatelessWidget {
  const CardComponentContainer({
    super.key,
    required this.snapshot,
    required this.cardWidgetKey,
    required this.initialViewHeight,
    required this.cardWidget,
  });

  final double initialViewHeight;
  final AsyncSnapshot snapshot;
  final Key cardWidgetKey;
  final Widget cardWidget;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          opacity: snapshot.data != null ? 1 : 0,
          child: SizedBox(
            key: cardWidgetKey,
            height: _determineHeight(snapshot),
            child: cardWidget,
          ),
        ),
        if (snapshot.data == null)
          SizedBox(
            height: initialViewHeight,
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

  double _determineHeight(AsyncSnapshot<dynamic> snapshot) {
    switch (snapshot.data) {
      case null:
        return initialViewHeight;
      case > 0:
        return snapshot.data;
      default:
        return initialViewHeight;
    }
  }
}
