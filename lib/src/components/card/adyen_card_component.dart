import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/card/card_advanced_component.dart';
import 'package:adyen_checkout/src/components/card/card_session_component.dart';
import 'package:adyen_checkout/src/utils/constants.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';
import 'package:adyen_checkout/src/utils/sdk_version_number_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class AdyenCardComponent extends StatelessWidget {
  final CardComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final _isStoredPaymentMethodIndicator =
      Constants.isStoredPaymentMethodIndicator;
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider();

  AdyenCardComponent({
    super.key,
    required this.configuration,
    required this.paymentMethod,
    required this.checkout,
    required this.onPaymentResult,
    this.gestureRecognizers,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sdkVersionNumberProvider.getSdkVersionNumber(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.data != null) {
          final sdkVersionNumber = snapshot.data ?? "";
          return switch (checkout) {
            SessionCheckout() => _buildCardSessionFlowWidget(sdkVersionNumber),
            AdvancedCheckout() => _buildCardAdvancedFlowWidget(sdkVersionNumber)
          };
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  CardSessionComponent _buildCardSessionFlowWidget(String sdkVersionNumber) {
    final SessionCheckout checkoutSession = checkout as SessionCheckout;
    final double initialHeight =
        _determineInitialHeight(configuration.cardConfiguration);
    final encodedPaymentMethod = json.encode(paymentMethod);
    final isStoredPaymentMethod =
        paymentMethod.containsKey(_isStoredPaymentMethodIndicator);

    return CardSessionComponent(
      cardComponentConfiguration: configuration.toDTO(sdkVersionNumber),
      paymentMethod: encodedPaymentMethod,
      session: checkoutSession.toDTO(),
      onPaymentResult: onPaymentResult,
      initialViewHeight: initialHeight,
      isStoredPaymentMethod: isStoredPaymentMethod,
    );
  }

  CardAdvancedComponent _buildCardAdvancedFlowWidget(String sdkVersionNumber) {
    final AdvancedCheckout checkoutAdvanced = checkout as AdvancedCheckout;
    final initialHeight =
        _determineInitialHeight(configuration.cardConfiguration);
    final encodedPaymentMethod = json.encode(paymentMethod);
    final isStoredPaymentMethod =
        paymentMethod.containsKey(_isStoredPaymentMethodIndicator);

    return CardAdvancedComponent(
      cardComponentConfiguration: configuration.toDTO(sdkVersionNumber),
      paymentMethod: encodedPaymentMethod,
      onPayments: checkoutAdvanced.postPayments,
      onPaymentsDetails: checkoutAdvanced.postPaymentsDetails,
      onPaymentResult: onPaymentResult,
      initialViewHeight: initialHeight,
      isStoredPaymentMethod: isStoredPaymentMethod,
      gestureRecognizers: gestureRecognizers,
    );
  }

  double _determineInitialHeight(CardConfiguration cardConfiguration) {
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
      CardConfiguration cardConfiguration) {
    double androidViewHeight = 294;

    if (cardConfiguration.holderNameRequired) {
      androidViewHeight += 61;
    }

    if (cardConfiguration.showStorePaymentField) {
      androidViewHeight += 43;
    }

    if (cardConfiguration.addressMode == AddressMode.full) {
      androidViewHeight += 422;
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

  double _determineInitialIosViewHeight(CardConfiguration cardConfiguration) {
    double iosViewHeight = 272;

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
