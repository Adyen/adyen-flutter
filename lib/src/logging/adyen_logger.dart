// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';

class AdyenLogger {
  static final AdyenLogger _instance = AdyenLogger._init();

  factory AdyenLogger() {
    return _instance;
  }

  AdyenLogger._init();

  bool _loggingEnabled = true;

  void enableLogging({required bool loggingEnabled}) {
    _loggingEnabled = loggingEnabled;
  }

  void print(String message) {
    if (kDebugMode && _loggingEnabled) {
      debugPrint("AdyenCheckout: $message");
    }
  }
}
