import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/google_pay/google_pay_advanced_component.dart';
import 'package:adyen_checkout/src/components/google_pay/google_pay_session_component.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart' as google_pay_sdk;

class AdyenGooglePayComponent extends StatelessWidget {
  final GooglePayComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Function(PaymentResult) onPaymentResult;
  final GooglePayButtonStyle? style;
  final Function()? onUnavailable;
  final Widget? unavailableWidget;
  final Widget? loadingIndicator;

  const AdyenGooglePayComponent({
    super.key,
    required this.configuration,
    required this.paymentMethod,
    required this.checkout,
    required this.onPaymentResult,
    this.style,
    this.onUnavailable,
    this.unavailableWidget,
    this.loadingIndicator,
  });

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return switch (checkout) {
          SessionCheckout() => _buildGooglePaySessionFlowWidget(),
          AdvancedCheckout() => _buildGooglePayAdvancedFlowWidget(),
        };
      default:
        throw Exception(
            "The Google Pay component is not supported on $defaultTargetPlatform");
    }
  }

  Widget _buildGooglePaySessionFlowWidget() {
    final String encodedPaymentMethod = json.encode(paymentMethod);
    return GooglePaySessionComponent(
      key: key,
      googlePayPaymentMethod: encodedPaymentMethod,
      googlePayComponentConfiguration: configuration,
      onPaymentResult: onPaymentResult,
      theme: _mapToGooglePayButtonTheme(),
      type: _mapToGooglePayButtonType(),
      cornerRadius: _determineCornerRadius(),
      width: _determineWidth(),
      height: _determineHeight(),
      loadingIndicator: loadingIndicator,
      onUnavailable: onUnavailable,
      unavailableWidget: unavailableWidget,
    );
  }

  Widget _buildGooglePayAdvancedFlowWidget() {
    final String encodedPaymentMethod = json.encode(paymentMethod);
    AdvancedCheckout advancedCheckout = checkout as AdvancedCheckout;
    return GooglePayAdvancedComponent(
      key: key,
      googlePayPaymentMethod: encodedPaymentMethod,
      googlePayComponentConfiguration: configuration,
      onPaymentResult: onPaymentResult,
      onSubmit: advancedCheckout.onSubmit,
      onAdditionalDetails: advancedCheckout.onAdditionalDetails,
      theme: _mapToGooglePayButtonTheme(),
      type: _mapToGooglePayButtonType(),
      cornerRadius: _determineCornerRadius(),
      width: _determineWidth(),
      height: _determineHeight(),
      loadingIndicator: loadingIndicator,
      onUnavailable: onUnavailable,
      unavailableWidget: unavailableWidget,
    );
  }

  int _determineCornerRadius() =>
      style?.cornerRadius ??
      google_pay_sdk.RawGooglePayButton.defaultButtonHeight ~/ 2;

  double _determineWidth() {
    final width =
        style?.width ?? google_pay_sdk.RawGooglePayButton.minimumButtonWidth;
    if (width > google_pay_sdk.RawGooglePayButton.minimumButtonWidth) {
      return width;
    }

    return google_pay_sdk.RawGooglePayButton.minimumButtonWidth;
  }

  double _determineHeight() {
    final height =
        style?.height ?? google_pay_sdk.RawGooglePayButton.defaultButtonHeight;
    if (height > google_pay_sdk.RawGooglePayButton.defaultButtonHeight) {
      return height;
    }

    return google_pay_sdk.RawGooglePayButton.defaultButtonHeight;
  }

  google_pay_sdk.GooglePayButtonTheme _mapToGooglePayButtonTheme() {
    switch (style?.theme) {
      case null:
        return google_pay_sdk.GooglePayButtonTheme.dark;
      case GooglePayButtonTheme.dark:
        return google_pay_sdk.GooglePayButtonTheme.dark;
      case GooglePayButtonTheme.light:
        return google_pay_sdk.GooglePayButtonTheme.light;
    }
  }

  google_pay_sdk.GooglePayButtonType _mapToGooglePayButtonType() {
    switch (style?.type) {
      case null:
        return google_pay_sdk.GooglePayButtonType.plain;
      case GooglePayButtonType.book:
        return google_pay_sdk.GooglePayButtonType.book;
      case GooglePayButtonType.buy:
        return google_pay_sdk.GooglePayButtonType.buy;
      case GooglePayButtonType.checkout:
        return google_pay_sdk.GooglePayButtonType.checkout;
      case GooglePayButtonType.donate:
        return google_pay_sdk.GooglePayButtonType.donate;
      case GooglePayButtonType.order:
        return google_pay_sdk.GooglePayButtonType.order;
      case GooglePayButtonType.pay:
        return google_pay_sdk.GooglePayButtonType.pay;
      case GooglePayButtonType.plain:
        return google_pay_sdk.GooglePayButtonType.plain;
      case GooglePayButtonType.subscribe:
        return google_pay_sdk.GooglePayButtonType.subscribe;
    }
  }
}
