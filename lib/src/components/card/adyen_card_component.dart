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

class AdyenCardComponent extends StatefulWidget {
  const AdyenCardComponent({
    super.key,
    required this.configuration,
    required this.paymentMethod,
    required this.checkout,
    required this.onPaymentResult,
    this.gestureRecognizers,
  });

  final CardComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  State<AdyenCardComponent> createState() => _AdyenCardComponentState();
}

class _AdyenCardComponentState extends State<AdyenCardComponent> {
  final _isStoredPaymentMethodIndicator = Constants.isStoredPaymentMethodIndicator;

  final SdkVersionNumberProvider _sdkVersionNumberProvider = SdkVersionNumberProvider.instance;

  late final Future<String> _sdkVersionNumber;

  @override
  void initState() {
    super.initState();
    _sdkVersionNumber = _sdkVersionNumberProvider.getSdkVersionNumber();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _sdkVersionNumber,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.data != null) {
          final sdkVersionNumber = snapshot.data ?? "";
          return switch (widget.checkout) {
            SessionCheckout() => _CardSessionFlowWidget(
              configuration: widget.configuration,
              paymentMethod: widget.paymentMethod,
              checkout: widget.checkout,
              onPaymentResult: widget.onPaymentResult,
              sdkVersionNumber: sdkVersionNumber,
              initialHeight: _determineInitialHeight(widget.configuration.cardConfiguration),
              isStoredPaymentMethod: widget.paymentMethod.containsKey(_isStoredPaymentMethodIndicator),
            ),
            AdvancedCheckout it => _CardAdvancedFlowWidget(
              configuration: widget.configuration,
              paymentMethod: widget.paymentMethod,
              advancedCheckout: it,
              onPaymentResult: widget.onPaymentResult,
              sdkVersionNumber: sdkVersionNumber,
              encodedPaymentMethod: json.encode(widget.paymentMethod),
              gestureRecognizers: widget.gestureRecognizers,
              initialHeight: _determineInitialHeight(widget.configuration.cardConfiguration),
              isStoredPaymentMethod: widget.paymentMethod.containsKey(_isStoredPaymentMethodIndicator),
            ),
          };
        } else {
          return Container(
            height: _determineInitialHeight(widget.configuration.cardConfiguration),
          );
        }
      },
    );
  }

  double _determineInitialHeight(CardConfiguration cardConfiguration) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _determineInitialAndroidViewHeight(cardConfiguration),
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

class _CardSessionFlowWidget extends StatelessWidget {
  const _CardSessionFlowWidget({
    required this.configuration,
    required this.paymentMethod,
    required this.checkout,
    required this.onPaymentResult,
    required this.sdkVersionNumber,
    required this.initialHeight,
    required this.isStoredPaymentMethod,
  });

  final CardComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final String sdkVersionNumber;
  final double initialHeight;
  final bool isStoredPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final encodedPaymentMethod = json.encode(paymentMethod);
    final sessionCheckout = checkout as SessionCheckout;

    return CardSessionComponent(
      cardComponentConfiguration: configuration.toDTO(sdkVersionNumber),
      paymentMethod: encodedPaymentMethod,
      session: sessionCheckout.toDTO(),
      onPaymentResult: onPaymentResult,
      initialViewHeight: initialHeight,
      isStoredPaymentMethod: isStoredPaymentMethod,
      onBinLookup: configuration.cardConfiguration.onBinLookup,
      onBinValue: configuration.cardConfiguration.onBinValue,
    );
  }
}

class _CardAdvancedFlowWidget extends StatelessWidget {
  const _CardAdvancedFlowWidget({
    required this.configuration,
    required this.paymentMethod,
    required this.onPaymentResult,
    required this.sdkVersionNumber,
    required this.encodedPaymentMethod,
    required this.advancedCheckout,
    required this.gestureRecognizers,
    required this.initialHeight,
    required this.isStoredPaymentMethod,
  });

  final CardComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final AdvancedCheckout advancedCheckout;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final String sdkVersionNumber;
  final String encodedPaymentMethod;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final double initialHeight;
  final bool isStoredPaymentMethod;

  @override
  Widget build(BuildContext context) {
    return CardAdvancedComponent(
      cardComponentConfiguration: configuration.toDTO(sdkVersionNumber),
      paymentMethod: encodedPaymentMethod,
      advancedCheckout: advancedCheckout,
      onPaymentResult: onPaymentResult,
      initialViewHeight: initialHeight,
      isStoredPaymentMethod: isStoredPaymentMethod,
      gestureRecognizers: gestureRecognizers,
      onBinLookup: configuration.cardConfiguration.onBinLookup,
      onBinValue: configuration.cardConfiguration.onBinValue,
    );
  }
}
