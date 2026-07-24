import 'package:flutter/foundation.dart';

class DropInFocusState {
  static final ValueNotifier<bool> active = ValueNotifier(false);

  static void activate() => active.value = true;

  static void deactivate() => active.value = false;
}
