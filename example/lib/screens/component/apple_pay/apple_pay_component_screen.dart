// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:flutter/material.dart';

class ApplePayComponentScreen extends StatefulWidget {
  const ApplePayComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenApplePayComponentRepository repository;

  @override
  State<ApplePayComponentScreen> createState() =>
      _ApplePayComponentScreenState();
}

class _ApplePayComponentScreenState extends State<ApplePayComponentScreen> {
  bool _useSession = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen google pay component')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSessionAdvancedFlowSwitch(_useSession),
              const SizedBox(height: 40),
              _useSession
                  ? _buildAdyenApplePaySessionComponent()
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionAdvancedFlowSwitch(bool useSession) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text(
          "Use session: ",
          style: TextStyle(fontSize: 20),
        ),
        Switch(
            value: useSession,
            onChanged: (value) {
              setState(() {
                _useSession = value;
              });
            }),
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _buildAdyenApplePaySessionComponent() {
    final ApplePayComponentConfiguration applePayComponentConfiguration =
        ApplePayComponentConfiguration(
      environment: Environment.test,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      applePayConfiguration: const ApplePayConfiguration(
        merchantId: Config.merchantId,
        merchantName: Config.merchantName,
      ),
    );

    return FutureBuilder<SessionCheckout>(
      future: widget.repository.createSessionCheckout(applePayComponentConfiguration),
      builder: (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
        if (snapshot.hasData) {
          final SessionCheckout sessionCheckout = snapshot.data!;
          final paymentMethod =
              _extractPaymentMethod(sessionCheckout.paymentMethodsJson);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Session flow",
              ),
              const SizedBox(height: 8),
              AdyenApplePayComponent(
                configuration: applePayComponentConfiguration,
                paymentMethod: paymentMethod,
                checkout: sessionCheckout,
                loadingIndicator: const CircularProgressIndicator(),
                style: ApplePayButtonStyle(
                  width: 200,
                  height: 48,
                ),
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

  Map<String, dynamic> _extractPaymentMethod(String paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    return jsonPaymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == "applepay",
      orElse: () => throw Exception("Apple pay payment method not provided"),
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
