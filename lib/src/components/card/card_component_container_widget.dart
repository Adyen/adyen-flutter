import 'package:flutter/material.dart';

class AdyenCardComponentContainerWidget extends StatelessWidget {
  const AdyenCardComponentContainerWidget({
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
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            child: SizedBox(
              key: cardWidgetKey,
              height: _determineHeight(snapshot),
              child: cardWidget,
            ),
          ),
        ),
        if (snapshot.data == null)
          SizedBox(
            height: initialViewHeight,
            child: const Center(child: CircularProgressIndicator()),
          )
      ],
    );
  }

  double _determineHeight(AsyncSnapshot<dynamic> snapshot) {
    if (snapshot.data == null) {
      return initialViewHeight;
    }
    if (snapshot.data > 0) {
      return snapshot.data;
    } else {
      return initialViewHeight;
    }
  }
}
