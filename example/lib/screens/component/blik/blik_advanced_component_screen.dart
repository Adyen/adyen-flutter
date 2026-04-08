import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_blik_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class BlikAdvancedComponentScreen extends StatelessWidget {
  const BlikAdvancedComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenBlikComponentRepository repository;

  @override
  Widget build(BuildContext context) {
    final blikConfiguration = BlikComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      shopperLocale: Config.shopperLocale,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Adyen BLIK component')),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: repository.fetchPaymentMethods(),
          builder: (BuildContext context,
              AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.hasData) {
              final paymentMethod = _extractPaymentMethod(snapshot.data!);
              if (paymentMethod.isEmpty) {
                return const Center(
                    child: Text('BLIK payment method not found'));
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    AdyenBlikComponent(
                      configuration: blikConfiguration,
                      paymentMethod: paymentMethod,
                      checkout: AdvancedCheckout(
                        paymentMethods: snapshot.data!,
                        onSubmit: repository.onSubmit,
                        onAdditionalDetails: repository.onAdditionalDetails,
                      ),
                      onPaymentResult: (paymentResult) async {
                        Navigator.pop(context);
                        DialogBuilder.showPaymentResultDialog(
                            paymentResult, context);
                      },
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Map<String, dynamic> _extractPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    return (paymentMethods['paymentMethods'] as List).firstWhere(
      (paymentMethod) => paymentMethod['type'] == 'blik',
      orElse: () => <String, dynamic>{},
    );
  }
}
