import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/google_pay/google_pay_session_component.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter/material.dart';

class AdyenGooglePayComponent extends StatelessWidget {
  final GooglePayComponentConfiguration configuration;
  final Map<String, dynamic> paymentMethod;
  final Checkout checkout;
  final Future<void> Function(PaymentResult) onPaymentResult;
  final ComponentPlatformApi _componentPlatformApi = ComponentPlatformApi();
  final ComponentFlutterApi _componentFlutterApi = ComponentFlutterApi();

  AdyenGooglePayComponent({
    super.key,
    required this.configuration,
    required this.paymentMethod,
    required this.checkout,
    required this.onPaymentResult,
  });

  @override
  Widget build(BuildContext context) {
    return switch (checkout) {
      SessionCheckout() => _buildGooglePaySessionFlowWidget(),
      AdvancedCheckout() => const Text("ADVANCED GOOGLE PAY")
    };
  }

  Widget _buildGooglePaySessionFlowWidget() {
    ComponentFlutterInterface.setup(_componentFlutterApi);
    final String encodedPaymentMethod = json.encode(paymentMethod);

    return GooglePaySessionComponent(
      googlePayPaymentMethod: encodedPaymentMethod,
      googlePayComponentConfiguration: configuration,
      onPaymentResult: onPaymentResult,
      componentPlatformApi: _componentPlatformApi,
      componentFlutterApi: _componentFlutterApi,
    );
  }
}
