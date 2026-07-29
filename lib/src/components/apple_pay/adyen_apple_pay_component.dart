import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_advanced_component.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_session_component.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The default width/height of a native `PKPaymentButton`, matching Apple's
/// Human Interface Guidelines for the Apple Pay button.
const double _minimumApplePayButtonWidth = 100;
const double _minimumApplePayButtonHeight = 30;

class AdyenApplePayComponent extends StatelessWidget {
  final CheckoutConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Function(PaymentResult) onPaymentResult;
  final ApplePayButtonStyle? style;
  final Function()? onUnavailable;
  final Widget? unavailableWidget;
  final Widget? loadingIndicator;
  final double? width;
  final double? height;

  const AdyenApplePayComponent({
    super.key,
    required this.configuration,
    required this.paymentMethod,
    required this.checkout,
    required this.onPaymentResult,
    this.style,
    this.onUnavailable,
    this.unavailableWidget,
    this.loadingIndicator,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (configuration.applePayConfiguration == null) {
      throw ArgumentError(
        'CheckoutConfiguration.applePayConfiguration must be set to use '
        'AdyenApplePayComponent.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        switch (checkout) {
          case SessionCheckout it:
            return ApplePaySessionComponent(
              key: key,
              session: it.toDTO(),
              applePayPaymentMethod: json.encode(paymentMethod),
              configuration: configuration,
              onPaymentResult: onPaymentResult,
              style: style,
              width: _determineWidth(),
              height: _determineHeight(),
              loadingIndicator: loadingIndicator,
              onUnavailable: onUnavailable,
              unavailableWidget: unavailableWidget,
            );
          case AdvancedCheckout it:
            if (configuration.amount == null) {
              AdyenLogger.instance.print(
                  "Apple Pay requires to set an amount when using the advanced flow.");
              onUnavailable?.call();
              return unavailableWidget ?? const SizedBox.shrink();
            }
            return ApplePayAdvancedComponent(
              key: key,
              applePayPaymentMethod: json.encode(paymentMethod),
              configuration: configuration,
              onPaymentResult: onPaymentResult,
              advancedCheckout: it,
              style: style,
              width: _determineWidth(),
              height: _determineHeight(),
              loadingIndicator: loadingIndicator,
              onUnavailable: onUnavailable,
              unavailableWidget: unavailableWidget,
            );
        }
      default:
        throw Exception(
            "The Apple Pay component is not supported on $defaultTargetPlatform");
    }
  }

  double _determineWidth() {
    final width = this.width ?? _minimumApplePayButtonWidth;
    if (width > _minimumApplePayButtonWidth) {
      return width;
    }

    return _minimumApplePayButtonWidth;
  }

  double _determineHeight() {
    final height = this.height ?? _minimumApplePayButtonHeight;
    if (height > _minimumApplePayButtonHeight) {
      return height;
    }

    return _minimumApplePayButtonHeight;
  }
}
