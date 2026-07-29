import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
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

  const AdyenComponent({
    super.key,
    required this.configuration,
    required this.checkout,
    required this.paymentMethod,
    required this.onPaymentResult,
    this.gestureRecognizers,
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
    final double initialHeight = _calculateInitialHeight(
      paymentMethodTxVariant,
      configuration.cardConfiguration,
    );
    final bool isStoredPaymentMethod = _isStoredPaymentMethod;
    return switch (checkout) {
      SessionCheckout it => AdyenSessionComponent(
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
