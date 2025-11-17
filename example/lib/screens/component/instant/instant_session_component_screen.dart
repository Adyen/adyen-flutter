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
            _buildAdyenInstantComponent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdyenInstantComponent() {
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
          final payByBankPaymentMethodResponse = _extractPaymentMethod(
              sessionCheckout.paymentMethods, "paybybank");
          final twintPaymentMethodResponse =
              _extractPaymentMethod(sessionCheckout.paymentMethods, "twint");

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Session flow",
              ),
              const SizedBox(height: 8),
              _buildPaymentButton(
                context,
                payPalPaymentMethodResponse,
                instantComponentConfiguration,
                sessionCheckout,
                'Paypal',
              ),
              _buildPaymentButton(
                context,
                klarnaPaymentMethodResponse,
                instantComponentConfiguration,
                sessionCheckout,
                'Klarna',
              ),
              _buildPaymentButton(
                context,
                idealPaymentMethodResponse,
                instantComponentConfiguration,
                sessionCheckout,
                'iDEAL',
              ),
              _buildPaymentButton(
                context,
                payByBankPaymentMethodResponse,
                instantComponentConfiguration,
                sessionCheckout,
                'Pay by Bank',
              ),
              _buildPaymentButton(
                context,
                twintPaymentMethodResponse,
                instantComponentConfiguration,
                sessionCheckout,
                'TWINT',
              ),
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

  Widget _buildPaymentButton(
    BuildContext context,
    Map<String, dynamic> paymentMethod,
    InstantComponentConfiguration instantComponentConfiguration,
    SessionCheckout sessionCheckout,
    String buttonText,
  ) {
    if (paymentMethod.isEmpty) {
      return const SizedBox.shrink();
    }

    return TextButton(
      onPressed: () => _startInstantPayment(
        context,
        paymentMethod,
        instantComponentConfiguration,
        sessionCheckout,
      ),
      child: Text(buttonText),
    );
  }

  Future<void> _startInstantPayment(
    BuildContext context,
    Map<String, dynamic> paymentMethod,
    InstantComponentConfiguration instantComponentConfiguration,
    SessionCheckout sessionCheckout,
  ) async {
    final PaymentResult paymentResult =
        await AdyenCheckout.session.startInstantComponent(
      configuration: instantComponentConfiguration,
      paymentMethod: paymentMethod,
      checkout: sessionCheckout,
    );

    if (context.mounted) {
      DialogBuilder.showPaymentResultDialog(paymentResult, context);
    }
  }
}
