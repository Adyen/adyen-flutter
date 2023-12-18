import 'dart:async';

import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_advanced.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_session.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';
import 'package:adyen_checkout/src/drop_in/drop_in_flutter_api.dart';
import 'package:adyen_checkout/src/drop_in/drop_in_platform_api.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/foundation.dart';

class AdyenCheckout implements AdyenCheckoutInterface {
  static AdyenCheckout? _instance;
  static AdyenCheckoutSession? _session;
  static AdyenCheckoutAdvanced? _advanced;
  static final AdyenCheckoutApi _adyenCheckoutApi = AdyenCheckoutApi();
  static final DropIn _dropIn = DropIn(
    SdkVersionNumberProvider(),
    DropInFlutterApi(),
    DropInPlatformApi(),
  );

  static AdyenCheckout get instance => _instance ??= AdyenCheckout._init();

  static AdyenCheckoutAdvanced get advanced =>
      _advanced ??= AdyenCheckoutAdvanced(_adyenCheckoutApi, _dropIn);

  static AdyenCheckoutSession get session =>
      _session ??= AdyenCheckoutSession(_adyenCheckoutApi, _dropIn);

  AdyenCheckout._init();

  @override
  Future<String> getReturnUrl() async => _adyenCheckoutApi.getReturnUrl();

  @override
  void enableConsoleLogging({required bool enabled}) {
    if (kDebugMode) {
      AdyenLogger.instance.enableConsoleLogging(loggingEnabled: enabled);
      _adyenCheckoutApi.enableConsoleLogging(enabled);
    }
  }
}
