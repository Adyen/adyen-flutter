import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class MobileSummerScreen extends StatelessWidget {
  const MobileSummerScreen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile Summer 2025')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => startDropInSessions(context),
                child: const Text("Drop-in sessions"),
              ),
              TextButton(
                onPressed: () => startDropInAdvancedFlow(context),
                child: const Text("Drop-in advanced flow"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> startDropInSessions(BuildContext context) async {
    try {
      final dropInConfiguration = _createDropInConfiguration();
      final sessionResponse = await repository.fetchSession();

      // Mobile Summer 2025 - Assignment 1:
      // Please provide the correct sessionData to the sessionData parameter for creating a sessionCheckout.
      final sessionCheckout = await AdyenCheckout.session.create(
        sessionId: sessionResponse["id"],
        sessionData: "Wrong sessionData",
        // sessionData: sessionResponse["sessionData"],
        configuration: dropInConfiguration,
      );

      final paymentResult = await AdyenCheckout.session.startDropIn(
        dropInConfiguration: dropInConfiguration,
        checkout: sessionCheckout,
      );

      if (context.mounted) {
        DialogBuilder.showPaymentResultDialog(paymentResult, context);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> startDropInAdvancedFlow(BuildContext context) async {
    try {
      final dropInConfiguration = _createDropInConfiguration();
      final paymentMethodsResponse = await repository.fetchPaymentMethods();

      // Mobile Summer 2025 - Assignment 2:
      // Check the referenced _onSubmit and _onAdditionalDetails method.
      final advancedCheckout = AdvancedCheckout(
        onSubmit: _onSubmit,
        onAdditionalDetails: _onAdditionalDetails,
      );

      final paymentResult = await AdyenCheckout.advanced.startDropIn(
        dropInConfiguration: dropInConfiguration,
        paymentMethods: paymentMethodsResponse,
        checkout: advancedCheckout,
      );

      if (context.mounted) {
        DialogBuilder.showPaymentResultDialog(paymentResult, context);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<PaymentEvent> _onSubmit(
    Map<String, dynamic> data, [
    Map<String, dynamic>? extra,
  ]) async {
    // Mobile Summer 2025 - Assignment 2.1
    // Is the /payments call made? Instead of returning a Error payment event, please call onSubmit of the repository.
    // return repository.onSubmit(data, extra);
    return Error(errorMessage: "Error - onSubmit() not called");
  }

  Future<PaymentEvent> _onAdditionalDetails(
      Map<String, dynamic> additionalDetails) async {
    // Mobile Summer 2025 - Assignment 2.3
    // Is the /payments/details call made? Instead of returning a Error payment event, please call onAdditionalDetails of the repository.
    // return repository.onAdditionalDetails(additionalDetails);
    return Error(errorMessage: "Error - onAdditionalDetails() not called");
  }

  DropInConfiguration _createDropInConfiguration() {
    // Mobile Summer 2025 - Assignment 3
    // Set the holderNameRequired to true.
    const cardConfiguration = CardConfiguration(
      // holderNameRequired: true,
    );

    return DropInConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      amount: Config.amount,
      cardConfiguration: cardConfiguration,
    );
  }
}
