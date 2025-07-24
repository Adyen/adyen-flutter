import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_advanced_component.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_session_component.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart' as pay_sdk;

class AdyenApplePayComponent extends StatelessWidget {
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

  final ApplePayComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Function(PaymentResult) onPaymentResult;
  final ApplePayButtonStyle? style;
  final Function()? onUnavailable;
  final Widget? unavailableWidget;
  final Widget? loadingIndicator;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => switch (checkout) {
          SessionCheckout it => ApplePaySessionComponent(
              key: key,
              session: it.toDTO(),
              applePayPaymentMethod: json.encode(paymentMethod),
              applePayComponentConfiguration: configuration,
              onPaymentResult: onPaymentResult,
              style: _mapToApplePayButtonStyle(),
              type: _mapToApplePayButtonType(),
              width: _determineWidth(),
              height: _determineHeight(),
              cornerRadius: style?.cornerRadius,
              loadingIndicator: loadingIndicator,
              onUnavailable: onUnavailable,
              unavailableWidget: unavailableWidget,
            ),
          AdvancedCheckout it => _ApplePayAdvancedFlowWidget(
              key: key,
              paymentMethod: paymentMethod,
              configuration: configuration,
              onPaymentResult: onPaymentResult,
              checkout: it,
              style: _mapToApplePayButtonStyle(),
              type: _mapToApplePayButtonType(),
              width: _determineWidth(),
              height: _determineHeight(),
              cornerRadius: style?.cornerRadius,
              loadingIndicator: loadingIndicator,
              onUnavailable: onUnavailable,
              unavailableWidget: unavailableWidget,
            ),
        },
      _ => throw Exception("The Apple Pay component is not supported on $defaultTargetPlatform"),
    };
  }

  double _determineWidth() {
    final width = this.width ?? pay_sdk.RawApplePayButton.minimumButtonWidth;
    if (width > pay_sdk.RawApplePayButton.minimumButtonWidth) {
      return width;
    }

    return pay_sdk.RawApplePayButton.minimumButtonWidth;
  }

  double _determineHeight() {
    final height = this.height ?? pay_sdk.RawApplePayButton.minimumButtonHeight;
    if (height > pay_sdk.RawApplePayButton.minimumButtonHeight) {
      return height;
    }

    return pay_sdk.RawApplePayButton.minimumButtonHeight;
  }

  pay_sdk.ApplePayButtonStyle _mapToApplePayButtonStyle() {
    return switch (style?.theme) {
      null => pay_sdk.ApplePayButtonStyle.black,
      ApplePayButtonTheme.white => pay_sdk.ApplePayButtonStyle.white,
      ApplePayButtonTheme.whiteOutline => pay_sdk.ApplePayButtonStyle.whiteOutline,
      ApplePayButtonTheme.black => pay_sdk.ApplePayButtonStyle.black,
      ApplePayButtonTheme.automatic => pay_sdk.ApplePayButtonStyle.automatic,
    };
  }

  pay_sdk.ApplePayButtonType _mapToApplePayButtonType() {
    return switch (style?.type) {
      null => pay_sdk.ApplePayButtonType.plain,
      ApplePayButtonType.plain => pay_sdk.ApplePayButtonType.plain,
      ApplePayButtonType.buy => pay_sdk.ApplePayButtonType.buy,
      ApplePayButtonType.setUp => pay_sdk.ApplePayButtonType.setUp,
      ApplePayButtonType.inStore => pay_sdk.ApplePayButtonType.inStore,
      ApplePayButtonType.donate => pay_sdk.ApplePayButtonType.donate,
      ApplePayButtonType.checkout => pay_sdk.ApplePayButtonType.checkout,
      ApplePayButtonType.book => pay_sdk.ApplePayButtonType.book,
      ApplePayButtonType.subscribe => pay_sdk.ApplePayButtonType.subscribe,
      ApplePayButtonType.reload => pay_sdk.ApplePayButtonType.reload,
      ApplePayButtonType.addMoney => pay_sdk.ApplePayButtonType.addMoney,
      ApplePayButtonType.topUp => pay_sdk.ApplePayButtonType.topUp,
      ApplePayButtonType.order => pay_sdk.ApplePayButtonType.order,
      ApplePayButtonType.rent => pay_sdk.ApplePayButtonType.rent,
      ApplePayButtonType.support => pay_sdk.ApplePayButtonType.support,
      ApplePayButtonType.contribute => pay_sdk.ApplePayButtonType.contribute,
      ApplePayButtonType.tip => pay_sdk.ApplePayButtonType.tip,
    };
  }
}

class _ApplePayAdvancedFlowWidget extends StatelessWidget {
  const _ApplePayAdvancedFlowWidget({
    super.key,
    required this.paymentMethod,
    required this.configuration,
    required this.onPaymentResult,
    required this.checkout,
    required this.style,
    required this.type,
    required this.width,
    required this.height,
    this.cornerRadius,
    this.loadingIndicator,
    this.unavailableWidget,
    this.onUnavailable,
  });

  final Map<String, dynamic> paymentMethod;
  final ApplePayComponentConfiguration configuration;
  final Function(PaymentResult result) onPaymentResult;
  final AdvancedCheckout checkout;
  final pay_sdk.ApplePayButtonStyle style;
  final pay_sdk.ApplePayButtonType type;
  final double width;
  final double height;
  final double? cornerRadius;
  final Widget? loadingIndicator;
  final Widget? unavailableWidget;
  final Function()? onUnavailable;

  @override
  Widget build(BuildContext context) {
    if (configuration.amount == null) {
      AdyenLogger.instance.print("Apple Pay requires to set an amount when using the advanced flow.");
      onUnavailable?.call();
      return unavailableWidget ?? const SizedBox.shrink();
    }

    return ApplePayAdvancedComponent(
      key: key,
      applePayPaymentMethod: json.encode(paymentMethod),
      applePayComponentConfiguration: configuration,
      onPaymentResult: onPaymentResult,
      advancedCheckout: checkout,
      style: style,
      type: type,
      width: width,
      height: height,
      cornerRadius: cornerRadius,
      loadingIndicator: loadingIndicator,
      onUnavailable: onUnavailable,
      unavailableWidget: unavailableWidget,
    );
  }
}
