import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_advanced_component.dart';
import 'package:adyen_checkout/src/components/apple_pay/apple_pay_session_component.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/v2/adyen_advanced_component.dart';
import 'package:adyen_checkout/src/v2/adyen_session_component.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class AdyenComponent extends StatelessWidget {
  final CheckoutConfiguration configuration;
  final Checkout checkout;
  final Map<String, dynamic> paymentMethod;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// Optional controller for observing readiness and submitting direct
  /// (no-input) payment methods such as iDEAL or PayPal.
  final AdyenComponentController? controller;

  /// Apple Pay-only, ignored for every other payment method.
  final Function()? onUnavailable;
  final Widget? unavailableWidget;
  final Widget? loadingIndicator;

  const AdyenComponent({
    super.key,
    this.controller,
    required this.configuration,
    required this.checkout,
    required this.paymentMethod,
    required this.onPaymentResult,
    this.gestureRecognizers,
    this.onUnavailable,
    this.unavailableWidget,
    this.loadingIndicator,
  });

  /// A payment method payload identifies a stored payment method by the
  /// presence of an `id` field (the recurring detail reference), the same
  /// way merchants distinguish stored vs. new payment methods when building
  /// the payment methods list. There's no separate merchant-facing flag for
  /// this: whether the flow is "stored" is entirely determined by which
  /// payment method payload the merchant chose to render.
  bool get _isStoredPaymentMethod =>
      paymentMethod.containsKey(Constants.isStoredPaymentMethodIndicator);

  @override
  Widget build(BuildContext context) {
    final String encodedPaymentMethod = json.encode(paymentMethod);
    final String paymentMethodTxVariant = paymentMethod["type"];

    if (paymentMethodTxVariant == "applepay") {
      return _buildApplePayComponent(encodedPaymentMethod);
    }

    final double initialHeight = _calculateInitialHeight(
      paymentMethodTxVariant,
      configuration.cardConfiguration,
    );
    final bool isStoredPaymentMethod = _isStoredPaymentMethod;
    return switch (checkout) {
      SessionCheckout it => AdyenSessionComponent(
          controller: controller,
          checkoutConfiguration: configuration.toDTO(),
          paymentMethod: encodedPaymentMethod,
          paymentMethodTxVariant: paymentMethodTxVariant,
          sessionCheckout: it,
          onPaymentResult: onPaymentResult,
          initialViewHeight: initialHeight,
          isStoredPaymentMethod: isStoredPaymentMethod,
          gestureRecognizers: gestureRecognizers,
          onBinLookup: configuration.cardConfiguration?.onBinLookup,
          onBinValue: configuration.cardConfiguration?.onBinValue,
        ),
      AdvancedCheckout it => AdyenAdvancedComponent(
          controller: controller,
          checkoutConfiguration: configuration.toDTO(),
          paymentMethod: encodedPaymentMethod,
          paymentMethodTxVariant: paymentMethodTxVariant,
          advancedCheckout: it,
          onPaymentResult: onPaymentResult,
          initialViewHeight: initialHeight,
          isStoredPaymentMethod: isStoredPaymentMethod,
          gestureRecognizers: gestureRecognizers,
          onBinLookup: configuration.cardConfiguration?.onBinLookup,
          onBinValue: configuration.cardConfiguration?.onBinValue,
        )
    };
  }

  Widget _buildApplePayComponent(String encodedPaymentMethod) {
    if (configuration.applePayConfiguration == null) {
      throw ArgumentError(
        'CheckoutConfiguration.applePayConfiguration must be set to use '
        'AdyenComponent with an Apple Pay payment method.',
      );
    }

    if (defaultTargetPlatform != TargetPlatform.iOS) {
      throw Exception("Apple Pay is not supported on $defaultTargetPlatform");
    }

    return switch (checkout) {
      SessionCheckout it => ApplePaySessionComponent(
          key: key,
          controller: controller,
          session: it.toDTO(),
          applePayPaymentMethod: encodedPaymentMethod,
          configuration: configuration,
          onPaymentResult: onPaymentResult,
          loadingIndicator: loadingIndicator,
          onUnavailable: onUnavailable,
          unavailableWidget: unavailableWidget,
        ),
      AdvancedCheckout it => _buildApplePayAdvancedComponent(
          encodedPaymentMethod,
          it,
        ),
    };
  }

  Widget _buildApplePayAdvancedComponent(
    String encodedPaymentMethod,
    AdvancedCheckout advancedCheckout,
  ) {
    if (configuration.amount == null) {
      AdyenLogger.instance.print(
          "Apple Pay requires to set an amount when using the advanced flow.");
      onUnavailable?.call();
      return unavailableWidget ?? const SizedBox.shrink();
    }
    return ApplePayAdvancedComponent(
      key: key,
      controller: controller,
      applePayPaymentMethod: encodedPaymentMethod,
      configuration: configuration,
      onPaymentResult: onPaymentResult,
      advancedCheckout: advancedCheckout,
      loadingIndicator: loadingIndicator,
      onUnavailable: onUnavailable,
      unavailableWidget: unavailableWidget,
    );
  }

  double _calculateInitialHeight(
    String paymentMethodTxVariant,
    CardConfiguration? cardConfiguration,
  ) {
    // Blik has no merchant-configurable options that affect its height, so a
    // flat, per-platform default is used instead of the card-specific
    // calculation below.
    if (paymentMethodTxVariant == "blik") {
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => 219,
        TargetPlatform.iOS => 213,
        _ => throw UnsupportedError('Unsupported platform view'),
      };
    }

    // Google Pay renders a single button, not a form, so it uses a flat
    // default matching the native button height instead of the
    // card-specific calculation below.
    if (paymentMethodTxVariant == "googlepay") {
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => 48,
        TargetPlatform.iOS => 48,
        _ => throw UnsupportedError('Unsupported platform view'),
      };
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _determineInitialAndroidViewHeight(cardConfiguration);
      case TargetPlatform.iOS:
        return _determineInitialIosViewHeight(cardConfiguration);
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }

  double _determineInitialAndroidViewHeight(
      CardConfiguration? cardConfiguration) {
    double androidViewHeight = 294;

    if (cardConfiguration == null) {
      return androidViewHeight;
    }

    if (cardConfiguration.holderNameRequired) {
      androidViewHeight += 61;
    }

    if (cardConfiguration.showStorePaymentField) {
      androidViewHeight += 84;
    }

    if (cardConfiguration.addressMode == AddressMode.full) {
      androidViewHeight += 650;
    }

    if (cardConfiguration.addressMode == AddressMode.postalCode) {
      androidViewHeight += 61;
    }

    if (cardConfiguration.socialSecurityNumberFieldVisibility ==
        FieldVisibility.show) {
      androidViewHeight += 61;
    }

    if (cardConfiguration.kcpFieldVisibility == FieldVisibility.show) {
      androidViewHeight += 164;
    }

    return androidViewHeight;
  }

  double _determineInitialIosViewHeight(CardConfiguration? cardConfiguration) {
    double iosViewHeight = 272;

    if (cardConfiguration == null) {
      return iosViewHeight;
    }

    if (cardConfiguration.holderNameRequired) {
      iosViewHeight += 63;
    }

    if (cardConfiguration.showStorePaymentField) {
      iosViewHeight += 55;
    }

    if (cardConfiguration.addressMode != AddressMode.none) {
      iosViewHeight += 63;
    }

    if (cardConfiguration.socialSecurityNumberFieldVisibility ==
        FieldVisibility.show) {
      iosViewHeight += 63;
    }

    if (cardConfiguration.kcpFieldVisibility == FieldVisibility.show) {
      iosViewHeight += 63;
    }

    return iosViewHeight;
  }
}
