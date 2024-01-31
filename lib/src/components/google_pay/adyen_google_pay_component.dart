import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/component_platform_api.dart';
import 'package:adyen_checkout/src/components/google_pay/google_pay_session_component.dart';
import 'package:flutter/material.dart';

class AdyenGooglePayComponent extends StatelessWidget {
  AdyenGooglePayComponent({
    super.key,
    required this.checkout,
    required this.googlePayComponentConfiguration,
  });

  final Checkout checkout;
  final GooglePayComponentConfiguration googlePayComponentConfiguration;
  final ComponentPlatformApi _componentPlatformApi = ComponentPlatformApi();

  @override
  Widget build(BuildContext context) {
    return switch (checkout) {
      SessionCheckout() =>
        _buildGooglePaySessionFlowWidget(checkout as SessionCheckout),
      AdvancedCheckout() => const Text("ADVANCED GOOGLE PAY")
    };
  }

  Widget _buildGooglePaySessionFlowWidget(SessionCheckout sessionCheckout) {
    final Map<String, dynamic> googlePayPaymentMethod =
        _extractPaymentMethod(sessionCheckout.paymentMethodsJson);
    final String encodedGooglePayPaymentMethod =
        json.encode(googlePayPaymentMethod);

    return GooglePaySessionComponent(
      componentPlatformApi: _componentPlatformApi,
      googlePayPaymentMethod: encodedGooglePayPaymentMethod,
      googlePayComponentConfiguration: googlePayComponentConfiguration,
    );
  }

  Map<String, dynamic> _extractPaymentMethod(String paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    return jsonPaymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == "googlepay",
      orElse: () => <String, String>{},
    );
  }
}
