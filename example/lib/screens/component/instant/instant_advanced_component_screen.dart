// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_instant_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class InstantAdvancedComponentScreen extends StatelessWidget {
  const InstantAdvancedComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenInstantComponentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen instant component')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            _buildAdyenGooglePayAdvancedComponent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdyenGooglePayAdvancedComponent() {
    return FutureBuilder<Map<String, dynamic>>(
      future: repository.fetchPaymentMethods(),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasData) {
          final AdvancedCheckout advancedCheckout = AdvancedCheckout(
            onSubmit: repository.onSubmit,
            onAdditionalDetails: repository.onAdditionalDetails,
          );

          final InstantComponentConfiguration instantComponentConfiguration =
              InstantComponentConfiguration(
            environment: Config.environment,
            clientKey: Config.clientKey,
            countryCode: Config.countryCode,
            amount: Config.amount,
          );

          final payPalPaymentMethodResponse =
              _extractPaymentMethod(snapshot.data!, "paypal");
          final klarnaPaymentMethodResponse =
              _extractPaymentMethod(snapshot.data!, "klarna");

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Advanced flow",
              ),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () {
                    AdyenCheckout.advanced
                        .startInstantComponent(
                          configuration: instantComponentConfiguration,
                          paymentMethodResponse: payPalPaymentMethodResponse,
                          checkout: advancedCheckout,
                        )
                        .then((paymentResult) =>
                            DialogBuilder.showPaymentResultDialog(
                                paymentResult, context));
                  },
                  child: const Text("Paypal")),
              TextButton(
                  onPressed: () {
                    AdyenCheckout.advanced
                        .startInstantComponent(
                          configuration: instantComponentConfiguration,
                          paymentMethodResponse: klarnaPaymentMethodResponse,
                          checkout: advancedCheckout,
                        )
                        .then((paymentResult) =>
                            DialogBuilder.showPaymentResultDialog(
                                paymentResult, context));
                  },
                  child: const Text("Klarna"))
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Map<String, dynamic> _extractPaymentMethod(
      Map<String, dynamic> paymentMethods, String key) {
    return paymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == key,
      orElse: () => throw Exception("$key payment method not provided"),
    );
  }
}
