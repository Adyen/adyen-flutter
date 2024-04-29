// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_instant_component_repository.dart';
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
    final InstantComponentConfiguration instantComponentConfiguration =
        InstantComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
    );

    return FutureBuilder<SessionCheckout>(
      future: repository.createSessionCheckout(instantComponentConfiguration),
      builder: (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
        if (snapshot.hasData) {
          final SessionCheckout sessionCheckout = snapshot.data!;
          final payPalPaymentMethod = _extractPaymentMethod(
              sessionCheckout.paymentMethodsJson, "paypal");
          final klarnaPaymentMethod = _extractPaymentMethod(
              sessionCheckout.paymentMethodsJson, "klarna");

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Session flow",
              ),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () async {
                    final paymentResult = await AdyenCheckout.session.start(
                      instantComponentConfiguration:
                          instantComponentConfiguration,
                      paymentMethodResponse: jsonEncode(payPalPaymentMethod),
                      checkout: sessionCheckout,
                    );

                    _dialogBuilder(paymentResult, context);
                  },
                  child: const Text("Paypal")),
              TextButton(
                  onPressed: () async {
                    final paymentResult = await AdyenCheckout.session.start(
                      instantComponentConfiguration:
                          instantComponentConfiguration,
                      paymentMethodResponse: jsonEncode(klarnaPaymentMethod),
                      checkout: sessionCheckout,
                    );

                    _dialogBuilder(paymentResult, context);
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
