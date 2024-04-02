import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/card/card_advanced_component.dart';
import 'package:adyen_checkout/src/components/card/card_session_component.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
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
      SdkVersionNumberProvider.instance;

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
            AdvancedCheckout it =>
              _buildCardAdvancedFlowWidget(sdkVersionNumber, it),
            AdvancedCheckoutPreview it =>
              _buildCardAdvancedFlowWidget(sdkVersionNumber, it),
          };
        } else {
          return Container(
            height: _determineInitialHeight(configuration.cardConfiguration),
          );
        }
      },
    );
  }

  CardSessionComponent _buildCardSessionFlowWidget(String sdkVersionNumber) {
    final SessionCheckout sessionCheckout = checkout as SessionCheckout;
    final String encodedPaymentMethod = json.encode(paymentMethod);
    final double initialHeight =
        _determineInitialHeight(configuration.cardConfiguration);
    final bool isStoredPaymentMethod =
        paymentMethod.containsKey(_isStoredPaymentMethodIndicator);

    return CardSessionComponent(
      cardComponentConfiguration: configuration.toDTO(sdkVersionNumber),
      paymentMethod: encodedPaymentMethod,
      session: sessionCheckout.toDTO(),
      onPaymentResult: onPaymentResult,
      initialViewHeight: initialHeight,
      isStoredPaymentMethod: isStoredPaymentMethod,
    );
  }

  CardAdvancedComponent _buildCardAdvancedFlowWidget(
    String sdkVersionNumber,
    Checkout advancedCheckout,
  ) {
    final initialHeight =
        _determineInitialHeight(configuration.cardConfiguration);
    final String encodedPaymentMethod = json.encode(paymentMethod);
    final bool isStoredPaymentMethod =
        paymentMethod.containsKey(_isStoredPaymentMethodIndicator);

    return CardAdvancedComponent(
      cardComponentConfiguration: configuration.toDTO(sdkVersionNumber),
      paymentMethod: encodedPaymentMethod,
      advancedCheckout: advancedCheckout,
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
