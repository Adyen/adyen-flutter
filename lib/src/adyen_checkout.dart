import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/common/models/base_configuration.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';
import 'package:adyen_checkout/src/utils/sdk_version_number_provider.dart';
import 'package:flutter/foundation.dart';

class AdyenCheckout implements AdyenCheckoutInterface {
  static AdyenCheckout? _instance;

  static AdyenCheckout get instance => _instance ??= AdyenCheckout._init();
  final AdyenLogger _adyenLogger = AdyenLogger.instance;
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider();
  final AdyenCheckoutApi _adyenCheckoutApi = AdyenCheckoutApi();
  late final DropIn _dropIn = DropIn(
    adyenLogger: _adyenLogger,
    sdkVersionNumberProvider: _sdkVersionNumberProvider,
  );

  AdyenCheckout._init();

  @override
  Future<String> getReturnUrl() async => _adyenCheckoutApi.getReturnUrl();

  @override
  Future<PaymentResult> startPayment({
    required DropInConfiguration dropInConfiguration,
    required DropInPaymentFlow paymentFlow,
  }) async =>
      _dropIn.startPayment(
        dropInConfiguration: dropInConfiguration,
        paymentFlow: paymentFlow,
      );

  @override
  void enableConsoleLogging({required bool enabled}) {
    if (kDebugMode) {
      _adyenLogger.enableConsoleLogging(loggingEnabled: enabled);
      _adyenCheckoutApi.enableConsoleLogging(enabled);
    }
  }

  @override
  Future<Session> createSession({
    required String sessionId,
    required String sessionData,
    required BaseConfiguration configuration,
  }) async {
    final sdkVersionNumber =
        await _sdkVersionNumberProvider.getSdkVersionNumber();

    if (configuration is CardComponentConfiguration) {
      SessionDTO sessionDTO = await _adyenCheckoutApi.createSession(
        sessionId,
        sessionData,
        configuration.toDTO(sdkVersionNumber),
      );
      return Session(
        id: sessionDTO.id,
        sessionData: sessionDTO.sessionData,
        paymentMethodsJson: sessionDTO.paymentMethodsJson,
      );
    } else {
      throw Exception("Configuration is not valid");
    }
  }
}
