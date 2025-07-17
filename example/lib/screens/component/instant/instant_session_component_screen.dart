// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_instant_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class InstantSessionComponentScreen extends StatelessWidget {
  const InstantSessionComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenInstantComponentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    final InstantComponentConfiguration instantComponentConfiguration =
        InstantComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
    );

    return FutureBuilder<SessionCheckout>(
      future: repository.createSessionCheckout(instantComponentConfiguration),
      builder: (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
        if (snapshot.hasData) {
          final SessionCheckout sessionCheckout = snapshot.data!;
          final payPalPaymentMethodResponse =
              _extractPaymentMethod(sessionCheckout.paymentMethods, "paypal");
          final klarnaPaymentMethodResponse =
              _extractPaymentMethod(sessionCheckout.paymentMethods, "klarna");
          final idealPaymentMethodResponse =
              _extractPaymentMethod(sessionCheckout.paymentMethods, "ideal");

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Session flow",
              ),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () {
                    AdyenCheckout.session
                        .startInstantComponent(
                      configuration: instantComponentConfiguration,
                      paymentMethod: payPalPaymentMethodResponse,
                      checkout: sessionCheckout,
                    )
                        .then((paymentResult) {
                      if (context.mounted) {
                        DialogBuilder.showPaymentResultDialog(
                            paymentResult, context);
                      }
                    });
                  },
                  child: const Text("Paypal")),
              TextButton(
                  onPressed: () {
                    AdyenCheckout.session
                        .startInstantComponent(
                      configuration: instantComponentConfiguration,
                      paymentMethod: klarnaPaymentMethodResponse,
                      checkout: sessionCheckout,
                    )
                        .then((paymentResult) {
                      if (context.mounted) {
                        DialogBuilder.showPaymentResultDialog(
                            paymentResult, context);
                      }
                    });
                  },
                  child: const Text("Klarna")),
              TextButton(
                  onPressed: () {
                    AdyenCheckout.session
                        .startInstantComponent(
                      configuration: instantComponentConfiguration,
                      paymentMethod: idealPaymentMethodResponse,
                      checkout: sessionCheckout,
                    )
                        .then((paymentResult) {
                      if (context.mounted) {
                        DialogBuilder.showPaymentResultDialog(
                            paymentResult, context);
                      }
                    });
                  },
                  child: const Text("iDEAL"))
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
      orElse: () => <String, dynamic>{},
    );
  }
}
