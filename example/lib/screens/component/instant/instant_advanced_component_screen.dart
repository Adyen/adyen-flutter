// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_instant_component_repository.dart';
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
    return FutureBuilder<String>(
      future: repository.fetchPaymentMethods(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasData) {
          final AdvancedCheckout advancedCheckout =
              AdvancedCheckout(
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
                            _dialogBuilder(paymentResult, context));
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
                            _dialogBuilder(paymentResult, context));
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
      String paymentMethods, String key) {
    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    return jsonPaymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == key,
      orElse: () => throw Exception("$key payment method not provided"),
    );
  }

  _dialogBuilder(PaymentResult paymentResult, BuildContext context) {
    String title = "";
    String message = "";
    switch (paymentResult) {
      case PaymentAdvancedFinished():
        title = "Finished";
        message = "Result code: ${paymentResult.resultCode}";
      case PaymentSessionFinished():
        title = "Finished";
        message = "Result code: ${paymentResult.resultCode}";
      case PaymentCancelledByUser():
        title = "Cancelled by user";
        message = "Cancelled by user";
      case PaymentError():
        title = "Error occurred";
        message = "${paymentResult.reason}";
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
