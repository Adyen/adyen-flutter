import 'package:adyen_checkout/src/drop_in/accessibility/drop_in_focus_state.dart';
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
      valueListenable: DropInFocusState.active,
      child: child,
      builder: (context, isDropInActive, child) {
        if (!isDropInActive) {
          return child!;
        }

        return ExcludeSemantics(
          excluding: true,
          child: Focus(
            canRequestFocus: false,
            descendantsAreFocusable: false,
            descendantsAreTraversable: false,
            child: child!,
          ),
        );
      },
    );
  }
}
