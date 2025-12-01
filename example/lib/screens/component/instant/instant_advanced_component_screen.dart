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
          );

          final payPalPaymentMethodResponse =
              _extractPaymentMethod(snapshot.data!, "paypal");
          final klarnaPaymentMethodResponse =
              _extractPaymentMethod(snapshot.data!, "klarna");
          final idealPaymentMethodResponse =
              _extractPaymentMethod(snapshot.data!, "ideal");
          final payByBankPaymentMethodResponse =
              _extractPaymentMethod(snapshot.data!, "paybybank");
          final twintPaymentMethodResponse =
              _extractPaymentMethod(snapshot.data!, "twint");

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Advanced flow",
              ),
              const SizedBox(height: 8),
              _buildPaymentButton(
                context,
                payPalPaymentMethodResponse,
                instantComponentConfiguration,
                advancedCheckout,
                'Paypal',
              ),
              _buildPaymentButton(
                context,
                klarnaPaymentMethodResponse,
                instantComponentConfiguration,
                advancedCheckout,
                'Klarna',
              ),
              _buildPaymentButton(
                context,
                idealPaymentMethodResponse,
                instantComponentConfiguration,
                advancedCheckout,
                'iDEAL',
              ),
              _buildPaymentButton(
                context,
                payByBankPaymentMethodResponse,
                instantComponentConfiguration,
                advancedCheckout,
                'Pay by bank',
              ),
              _buildPaymentButton(
                context,
                twintPaymentMethodResponse,
                instantComponentConfiguration,
                advancedCheckout,
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
    AdvancedCheckout advancedCheckout,
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
        advancedCheckout,
      ),
      child: Text(buttonText),
    );
  }

  Future<void> _startInstantPayment(
    BuildContext context,
    Map<String, dynamic> paymentMethod,
    InstantComponentConfiguration instantComponentConfiguration,
    AdvancedCheckout advancedCheckout,
  ) async {
    final paymentResult = await AdyenCheckout.advanced.startInstantComponent(
      configuration: instantComponentConfiguration,
      paymentMethod: paymentMethod,
      checkout: advancedCheckout,
    );

    if (context.mounted) {
      DialogBuilder.showPaymentResultDialog(paymentResult, context);
    }
  }
}
