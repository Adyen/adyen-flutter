import 'package:adyen_checkout/src/drop_in/drop_in_activity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AdyenDropInFocusScope extends StatelessWidget {
  const AdyenDropInFocusScope({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return child;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: DropInActivity.active,
      child: child,
      builder: (context, isDropInActive, child) => ExcludeSemantics(
        excluding: isDropInActive,
        child: Focus(
          canRequestFocus: !isDropInActive,
          descendantsAreFocusable: !isDropInActive,
          descendantsAreTraversable: !isDropInActive,
          child: child!,
        ),
      ),
    );
  }
}
