import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/google_pay/google_pay_advanced_component.dart';
import 'package:adyen_checkout/src/components/google_pay/google_pay_session_component.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart' as google_pay_sdk;

class AdyenGooglePayComponent extends StatelessWidget {
  final GooglePayComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final GooglePayButtonTheme? theme;
  final GooglePayButtonType? type;
  final int? cornerRadius;
  final double? width;
  final double? height;
  final Future<void> Function()? onGooglePayUnavailable;
  final Widget? googlePayUnavailableWidget;
  final Widget? loadingIndicator;

  const AdyenGooglePayComponent({
    super.key,
    required this.configuration,
    required this.paymentMethod,
    required this.checkout,
    required this.onPaymentResult,
    this.theme,
    this.type,
    this.cornerRadius,
    this.width,
    this.height,
    this.onGooglePayUnavailable,
    this.googlePayUnavailableWidget,
    this.loadingIndicator,
  });

  @override
  Widget build(BuildContext context) {
    return switch (checkout) {
      SessionCheckout() => _buildGooglePaySessionFlowWidget(),
      AdvancedCheckout() => _buildGooglePayAdvancedFlowWidget(),
    };
  }

  Widget _buildGooglePaySessionFlowWidget() {
    final String encodedPaymentMethod = json.encode(paymentMethod);
    return GooglePaySessionComponent(
      key: key,
      googlePayPaymentMethod: encodedPaymentMethod,
      googlePayComponentConfiguration: configuration,
      onPaymentResult: onPaymentResult,
      onGooglePayUnavailable: onGooglePayUnavailable,
      cornerRadius: cornerRadius,
      width: _determineWidth(),
      height: _determineHeight(),
      loadingIndicator: loadingIndicator,
      googlePayUnavailableWidget: googlePayUnavailableWidget,
      theme: _mapToGooglePayButtonTheme(),
      type: _mapToGooglePayButtonType(),
    );
  }

  Widget _buildGooglePayAdvancedFlowWidget() {
    final String encodedPaymentMethod = json.encode(paymentMethod);
    AdvancedCheckout advancedCheckout = checkout as AdvancedCheckout;
    return GooglePayAdvancedComponent(
      key: key,
      googlePayPaymentMethod: encodedPaymentMethod,
      googlePayComponentConfiguration: configuration,
      onSubmit: advancedCheckout.onSubmit,
      onAdditionalDetails: advancedCheckout.onAdditionalDetails,
      onPaymentResult: onPaymentResult,
      onGooglePayUnavailable: onGooglePayUnavailable,
      cornerRadius: cornerRadius,
      width: _determineWidth(),
      height: _determineHeight(),
      loadingIndicator: loadingIndicator,
      googlePayUnavailableWidget: googlePayUnavailableWidget,
      theme: _mapToGooglePayButtonTheme(),
      type: _mapToGooglePayButtonType(),
    );
  }

  double _determineWidth() {
    if (width != null) {
      if (width! >= google_pay_sdk.RawGooglePayButton.minimumButtonWidth) {
        return width!;
      }
    }
    return google_pay_sdk.RawGooglePayButton.minimumButtonWidth;
  }

  double _determineHeight() {
    if (height != null) {
      if (height! >= google_pay_sdk.RawGooglePayButton.defaultButtonHeight) {
        return height!;
      }
    }
    return google_pay_sdk.RawGooglePayButton.defaultButtonHeight;
  }

  google_pay_sdk.GooglePayButtonTheme? _mapToGooglePayButtonTheme() {
    switch (theme) {
      case null:
        return null;
      case GooglePayButtonTheme.dark:
        return google_pay_sdk.GooglePayButtonTheme.dark;
      case GooglePayButtonTheme.light:
        return google_pay_sdk.GooglePayButtonTheme.light;
    }
  }

  google_pay_sdk.GooglePayButtonType? _mapToGooglePayButtonType() {
    switch (type) {
      case null:
        return null;
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
