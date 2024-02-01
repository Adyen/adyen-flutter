// ignore_for_file: unused_local_variable

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAdyenGooglePayComponent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdyenGooglePayComponent() {
    return FutureBuilder<SessionCheckout>(
      future: repository.createSessionCheckout(),
      builder: (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
        if (snapshot.hasData) {
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

          return AdyenGooglePayComponent(
            checkout: sessionCheckout,
            googlePayComponentConfiguration: googlePayComponentConfiguration,
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}