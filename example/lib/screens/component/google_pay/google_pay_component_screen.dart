// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_google_pay_component_repository.dart';
import 'package:flutter/material.dart';

class GooglePayComponentScreen extends StatelessWidget {
  const GooglePayComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenGooglePayComponentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen google pay component')),
      body: SafeArea(
        child: Center(
          child: _buildAdyenGooglePayComponent(),
        ),
      ),
    );
  }

  Widget _buildAdyenGooglePayComponent() {
    return FutureBuilder<SessionCheckout>(
      future: repository.createSessionCheckout(),
      builder: (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
        if (snapshot.hasData) {
          AdyenCheckout.instance.enableConsoleLogging(enabled: true);

          final SessionCheckout sessionCheckout = snapshot.data!;

          final GooglePayComponentConfiguration
              googlePayComponentConfiguration = GooglePayComponentConfiguration(
            environment: Environment.test,
            clientKey: Config.clientKey,
            countryCode: Config.countryCode,
            amount: Config.amount,
            googlePayConfiguration: const GooglePayConfiguration(
              googlePayEnvironment: Config.googlePayEnvironment,
            ),
          );

          final paymentMethod =
              _extractPaymentMethod(sessionCheckout.paymentMethodsJson);

          final cardComponentConfiguration = CardComponentConfiguration(
            environment: Config.environment,
            clientKey: Config.clientKey,
            countryCode: Config.countryCode,
            amount: Config.amount,
            shopperLocale: Config.shopperLocale,
            cardConfiguration: const CardConfiguration(),
          );

          final cardPaymentMethod =
              _extractCardPaymentMethod(sessionCheckout.paymentMethodsJson);

          return Column(
            children: [
              AdyenCardComponent(
                configuration: cardComponentConfiguration,
                paymentMethod: cardPaymentMethod,
                checkout: sessionCheckout,
                onPaymentResult: (paymentResult) async {
                  Navigator.pop(context);
                  _dialogBuilder(paymentResult, context);
                },
              ),
              AdyenGooglePayComponent(
                configuration: googlePayComponentConfiguration,
                paymentMethod: paymentMethod,
                checkout: sessionCheckout,
                type: GooglePayButtonType.plain,
                loadingIndicator: const CircularProgressIndicator(),
                onPaymentResult: (paymentResult) {
                  Navigator.pop(context);
                  _dialogBuilder(paymentResult, context);
                },
                onSetupError: () {},
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Map<String, dynamic> _extractCardPaymentMethod(String paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    List paymentMethodList = jsonPaymentMethods["paymentMethods"] as List;
    Map<String, dynamic> paymentMethod = paymentMethodList
        .firstWhere((paymentMethod) => paymentMethod["type"] == "scheme");

    List storedPaymentMethodList =
        jsonPaymentMethods.containsKey("storedPaymentMethods")
            ? jsonPaymentMethods["storedPaymentMethods"] as List
            : [];
    Map<String, dynamic> storedPaymentMethod =
        storedPaymentMethodList.firstOrNull ?? <String, String>{};

    return paymentMethod;
  }

  Map<String, dynamic> _extractPaymentMethod(String paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    return jsonPaymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == "googlepay",
      orElse: () => throw Exception("Google pay payment method not provided"),
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
