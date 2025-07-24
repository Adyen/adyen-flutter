import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/google_pay/google_pay_advanced_component.dart';
import 'package:adyen_checkout/src/components/google_pay/google_pay_session_component.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
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
  final double? width;
  final double? height;

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
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
      switch (checkout) {
        SessionCheckout it =>
            GooglePaySessionComponent(
              key: key,
              session: it.toDTO(),
              googlePayPaymentMethod: json.encode(paymentMethod),
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
            ),
        AdvancedCheckout it =>
            GooglePayAdvancedComponent(
              key: key,
              googlePayPaymentMethod: json.encode(paymentMethod),
              googlePayComponentConfiguration: configuration,
              onPaymentResult: onPaymentResult,
              advancedCheckout: it,
              theme: _mapToGooglePayButtonTheme(),
              type: _mapToGooglePayButtonType(),
              cornerRadius: _determineCornerRadius(),
              width: _determineWidth(),
              height: _determineHeight(),
              loadingIndicator: loadingIndicator,
              onUnavailable: onUnavailable,
              unavailableWidget: unavailableWidget,
            ),
      },
      _ => throw Exception("The Google Pay component is not supported on $defaultTargetPlatform"),
    };
  }

  int _determineCornerRadius() =>
      style?.cornerRadius ??
      google_pay_sdk.RawGooglePayButton.defaultButtonHeight ~/ 2;

  double _determineWidth() {
    final width =
        this.width ?? google_pay_sdk.RawGooglePayButton.minimumButtonWidth;
    if (width > google_pay_sdk.RawGooglePayButton.minimumButtonWidth) {
      return width;
    }

    return google_pay_sdk.RawGooglePayButton.minimumButtonWidth;
  }

  double _determineHeight() {
    final height =
        this.height ?? google_pay_sdk.RawGooglePayButton.defaultButtonHeight;
    if (height > google_pay_sdk.RawGooglePayButton.defaultButtonHeight) {
      return height;
    }

    return google_pay_sdk.RawGooglePayButton.defaultButtonHeight;
  }

  google_pay_sdk.GooglePayButtonTheme _mapToGooglePayButtonTheme() {
    return switch (style?.theme) {
      null => google_pay_sdk.GooglePayButtonTheme.dark,
      GooglePayButtonTheme.dark => google_pay_sdk.GooglePayButtonTheme.dark,
      GooglePayButtonTheme.light => google_pay_sdk.GooglePayButtonTheme.light,
    };
  }

  google_pay_sdk.GooglePayButtonType _mapToGooglePayButtonType() {
    return switch (style?.type) {
      null => google_pay_sdk.GooglePayButtonType.plain,
      GooglePayButtonType.book => google_pay_sdk.GooglePayButtonType.book,
      GooglePayButtonType.buy => google_pay_sdk.GooglePayButtonType.buy,
      GooglePayButtonType.checkout => google_pay_sdk.GooglePayButtonType.checkout,
      GooglePayButtonType.donate => google_pay_sdk.GooglePayButtonType.donate,
      GooglePayButtonType.order => google_pay_sdk.GooglePayButtonType.order,
      GooglePayButtonType.pay => google_pay_sdk.GooglePayButtonType.pay,
      GooglePayButtonType.plain => google_pay_sdk.GooglePayButtonType.plain,
      GooglePayButtonType.subscribe => google_pay_sdk.GooglePayButtonType.subscribe,
    };
  }
}
