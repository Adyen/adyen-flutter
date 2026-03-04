import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/blik/blik_advanced_component.dart';
import 'package:adyen_checkout/src/components/blik/blik_session_component.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AdyenBlikComponent extends StatelessWidget {
  final BlikComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider.instance;

  AdyenBlikComponent({
    super.key,
    required this.configuration,
    required this.paymentMethod,
    required this.checkout,
    required this.onPaymentResult,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sdkVersionNumberProvider.getSdkVersionNumber(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.data != null) {
          final sdkVersionNumber = snapshot.data ?? "";
          return switch (checkout) {
            SessionCheckout() => _buildBlikSessionFlowWidget(sdkVersionNumber),
            AdvancedCheckout it =>
              _buildBlikAdvancedFlowWidget(sdkVersionNumber, it),
          };
        } else {
          return Container(height: _determineInitialHeight());
        }
      },
    );
  }

  BlikSessionComponent _buildBlikSessionFlowWidget(String sdkVersionNumber) {
    final SessionCheckout sessionCheckout = checkout as SessionCheckout;
    final String encodedPaymentMethod = json.encode(paymentMethod);

    return BlikSessionComponent(
      blikComponentConfiguration: configuration.toDTO(sdkVersionNumber),
      paymentMethod: encodedPaymentMethod,
      session: sessionCheckout.toDTO(),
      onPaymentResult: onPaymentResult,
      initialViewHeight: _determineInitialHeight(),
    );
  }

  BlikAdvancedComponent _buildBlikAdvancedFlowWidget(
    String sdkVersionNumber,
    AdvancedCheckout advancedCheckout,
  ) {
    final String encodedPaymentMethod = json.encode(paymentMethod);

    return BlikAdvancedComponent(
      blikComponentConfiguration: configuration.toDTO(sdkVersionNumber),
      paymentMethod: encodedPaymentMethod,
      advancedCheckout: advancedCheckout,
      onPaymentResult: onPaymentResult,
      initialViewHeight: _determineInitialHeight(),
    );
  }

  double _determineInitialHeight() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 219;
      case TargetPlatform.iOS:
        return 213;
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }
}
