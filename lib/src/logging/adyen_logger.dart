// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

class AdyenLogger {
  static AdyenLogger? _instance;

  AdyenLogger._init();

  static AdyenLogger get instance => _instance ??= AdyenLogger._init();

  bool _loggingEnabled = false;

  void enableConsoleLogging({required bool loggingEnabled}) {
    _loggingEnabled = loggingEnabled;
  }

  void print(String message) {
    if (kDebugMode && _loggingEnabled) {
      debugPrint("AdyenCheckout: $message");
    }
  }
}
