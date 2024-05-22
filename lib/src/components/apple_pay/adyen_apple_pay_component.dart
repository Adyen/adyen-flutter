import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_advanced_component.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_session_component.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart' as pay_sdk;

class AdyenApplePayComponent extends StatelessWidget {
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
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return switch (checkout) {
          SessionCheckout it => _buildApplePaySessionFlowWidget(it),
          AdvancedCheckout it => _buildApplePayAdvancedFlowWidget(it),
        };
      default:
        throw Exception(
            "The Apple Pay component is not supported on $defaultTargetPlatform");
    }
  }

  Widget _buildApplePaySessionFlowWidget(SessionCheckout sessionCheckout) {
    return ApplePaySessionComponent(
      key: key,
      session: sessionCheckout.toDTO(),
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
    );
  }

  Widget _buildApplePayAdvancedFlowWidget(
      AdvancedCheckout advancedCheckout) {
    return ApplePayAdvancedComponent(
      key: key,
      applePayPaymentMethod: json.encode(paymentMethod),
      applePayComponentConfiguration: configuration,
      onPaymentResult: onPaymentResult,
      advancedCheckout: advancedCheckout,
      style: _mapToApplePayButtonStyle(),
      type: _mapToApplePayButtonType(),
      width: _determineWidth(),
      height: _determineHeight(),
      cornerRadius: style?.cornerRadius,
      loadingIndicator: loadingIndicator,
      onUnavailable: onUnavailable,
      unavailableWidget: unavailableWidget,
    );
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
    switch (style?.theme) {
      case null:
        return pay_sdk.ApplePayButtonStyle.black;
      case ApplePayButtonTheme.white:
        return pay_sdk.ApplePayButtonStyle.white;
      case ApplePayButtonTheme.whiteOutline:
        return pay_sdk.ApplePayButtonStyle.whiteOutline;
      case ApplePayButtonTheme.black:
        return pay_sdk.ApplePayButtonStyle.black;
      case ApplePayButtonTheme.automatic:
        return pay_sdk.ApplePayButtonStyle.automatic;
    }
  }

  pay_sdk.ApplePayButtonType _mapToApplePayButtonType() {
    switch (style?.type) {
      case null:
        return pay_sdk.ApplePayButtonType.plain;
      case ApplePayButtonType.plain:
        return pay_sdk.ApplePayButtonType.plain;
      case ApplePayButtonType.buy:
        return pay_sdk.ApplePayButtonType.buy;
      case ApplePayButtonType.setUp:
        return pay_sdk.ApplePayButtonType.setUp;
      case ApplePayButtonType.inStore:
        return pay_sdk.ApplePayButtonType.inStore;
      case ApplePayButtonType.donate:
        return pay_sdk.ApplePayButtonType.donate;
      case ApplePayButtonType.checkout:
        return pay_sdk.ApplePayButtonType.checkout;
      case ApplePayButtonType.book:
        return pay_sdk.ApplePayButtonType.book;
      case ApplePayButtonType.subscribe:
        return pay_sdk.ApplePayButtonType.subscribe;
      case ApplePayButtonType.reload:
        return pay_sdk.ApplePayButtonType.reload;
      case ApplePayButtonType.addMoney:
        return pay_sdk.ApplePayButtonType.addMoney;
      case ApplePayButtonType.topUp:
        return pay_sdk.ApplePayButtonType.topUp;
      case ApplePayButtonType.order:
        return pay_sdk.ApplePayButtonType.order;
      case ApplePayButtonType.rent:
        return pay_sdk.ApplePayButtonType.rent;
      case ApplePayButtonType.support:
        return pay_sdk.ApplePayButtonType.support;
      case ApplePayButtonType.contribute:
        return pay_sdk.ApplePayButtonType.contribute;
      case ApplePayButtonType.tip:
        return pay_sdk.ApplePayButtonType.tip;
    }
  }
}
