// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

class AdyenLogger {
  var _loggingEnabled = false;

  void log(String message) {
    if (kDebugMode && _loggingEnabled) {
      debugPrint(message);
    }
  }

  void shouldLog(bool enabled) => _loggingEnabled = enabled;
}
