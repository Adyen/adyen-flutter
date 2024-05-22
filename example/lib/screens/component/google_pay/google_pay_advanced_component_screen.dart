// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_google_pay_component_repository.dart';
import 'package:flutter/material.dart';

class GooglePayAdvancedComponentScreen extends StatelessWidget {
  const GooglePayAdvancedComponentScreen({
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

          final GooglePayComponentConfiguration
              googlePayComponentConfiguration = GooglePayComponentConfiguration(
            environment: Config.environment,
            clientKey: Config.clientKey,
            countryCode: Config.countryCode,
            amount: Config.amount,
            googlePayConfiguration: const GooglePayConfiguration(
              googlePayEnvironment: Config.googlePayEnvironment,
              shippingAddressRequired: true,
            ),
          );

          final GooglePayButtonStyle googlePayButtonStyle =
              GooglePayButtonStyle(
            theme: GooglePayButtonTheme.light,
            type: GooglePayButtonType.buy,
            cornerRadius: 4,
          );

          final paymentMethod = _extractPaymentMethod(snapshot.data!);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Advanced flow",
              ),
              const SizedBox(height: 8),
              AdyenGooglePayComponent(
                configuration: googlePayComponentConfiguration,
                paymentMethod: paymentMethod,
                checkout: advancedCheckout,
                style: googlePayButtonStyle,
                loadingIndicator: const CircularProgressIndicator(),
                width: 250,
                onPaymentResult: (paymentResult) {
                  Navigator.pop(context);
                  _dialogBuilder(paymentResult, context);
                },
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
      Map<String, dynamic> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    return paymentMethods["paymentMethods"].firstWhere(
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
