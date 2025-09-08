import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/card/card_advanced_component.dart';
import 'package:adyen_checkout/src/components/card/card_session_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/util/constants.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class AdyenCardComponent extends StatefulWidget {
  final CardComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  const AdyenCardComponent({
    super.key,
    required this.configuration,
    required this.paymentMethod,
    required this.checkout,
    required this.onPaymentResult,
    this.gestureRecognizers,
  });

  @override
  State<AdyenCardComponent> createState() => _AdyenCardComponentState();
}

class _AdyenCardComponentState extends State<AdyenCardComponent> {
  late final Future<String> _sdkVersionNumberFuture;

  @override
  void initState() {
    super.initState();
    _sdkVersionNumberFuture =
        SdkVersionNumberProvider.instance.getSdkVersionNumber();
  }

  @override
  Widget build(BuildContext context) {
    final double initialViewHeight =
        _determineInitialHeight(widget.configuration.cardConfiguration);
    final bool isStoredPaymentMethod = widget.paymentMethod
        .containsKey(Constants.isStoredPaymentMethodIndicator);
    final String encodedPaymentMethod = json.encode(widget.paymentMethod);

    return FutureBuilder<String>(
      future: _sdkVersionNumberFuture,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        final String? sdkVersion = snapshot.data;
        if (sdkVersion == null) {
          return Container(height: initialViewHeight);
        }

        final CardComponentConfigurationDTO cardComponentConfiguration =
            widget.configuration.toDTO(sdkVersion);
        return switch (widget.checkout) {
          SessionCheckout it => CardSessionComponent(
              cardComponentConfiguration: cardComponentConfiguration,
              session: it.toDTO(),
              paymentMethod: encodedPaymentMethod,
              onPaymentResult: widget.onPaymentResult,
              initialViewHeight: initialViewHeight,
              isStoredPaymentMethod: isStoredPaymentMethod,
              gestureRecognizers: widget.gestureRecognizers,
              onBinLookup: widget.configuration.cardConfiguration.onBinLookup,
              onBinValue: widget.configuration.cardConfiguration.onBinValue,
            ),
          AdvancedCheckout it => CardAdvancedComponent(
              cardComponentConfiguration: cardComponentConfiguration,
              paymentMethod: encodedPaymentMethod,
              onPaymentResult: widget.onPaymentResult,
              advancedCheckout: it,
              initialViewHeight: initialViewHeight,
              isStoredPaymentMethod: isStoredPaymentMethod,
              gestureRecognizers: widget.gestureRecognizers,
              onBinLookup: widget.configuration.cardConfiguration.onBinLookup,
              onBinValue: widget.configuration.cardConfiguration.onBinValue,
            )
        };
      },
    );
  }

  double _determineInitialHeight(CardConfiguration cardConfiguration) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _determineInitialAndroidViewHeight(cardConfiguration),
      TargetPlatform.iOS => _determineInitialIosViewHeight(cardConfiguration),
      _ => throw UnsupportedError('Unsupported platform view'),
    };
  }

  double _determineInitialAndroidViewHeight(
      CardConfiguration cardConfiguration) {
    double androidViewHeight = 294;

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
