import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:flutter/material.dart';

class V2Screen extends StatelessWidget {
  const V2Screen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('V2 Example')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => setupSession(),
                child: const Text("TODO: Drop-in sessions"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> setupSession() async {
    try {
      final sessionResponse = await repository.fetchSession().then(
            (sessionResponseBody) => SessionResponse(
              sessionResponseBody['id'],
              sessionResponseBody['sessionData'],
            ),
          );

      final checkoutConfiguration = _createCheckoutConfiguration();
      final sessionCheckout = await AdyenCheckout.session.setup(
        sessionResponse: sessionResponse,
        checkoutConfiguration: checkoutConfiguration,
      );
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  CheckoutConfiguration _createCheckoutConfiguration() {
    return CheckoutConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      amount: Config.amount,
      cardConfiguration: const CardConfiguration(
        holderNameRequired: true,
      ),
    );
  }
}
