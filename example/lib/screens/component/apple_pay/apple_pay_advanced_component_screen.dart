// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class ApplePayAdvancedComponentScreen extends StatelessWidget {
  const ApplePayAdvancedComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenApplePayComponentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen Apple Pay component')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildAdyenApplePayAdvancedComponent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdyenApplePayAdvancedComponent() {
    final ApplePayComponentConfiguration applePayComponentConfiguration =
        ApplePayComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      applePayConfiguration: _createApplePayConfiguration(),
    );

    return FutureBuilder<Map<String, dynamic>>(
      future: repository.fetchPaymentMethods(),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasData) {
          final AdvancedCheckout advancedCheckout = AdvancedCheckout(
              onSubmit: repository.onSubmit,
              onAdditionalDetails: repository.onAdditionalDetailsMock);
          final paymentMethod = _extractPaymentMethod(snapshot.data!);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Advanced flow",
              ),
              const SizedBox(height: 8),
              AdyenApplePayComponent(
                configuration: applePayComponentConfiguration,
                paymentMethod: paymentMethod,
                checkout: advancedCheckout,
                loadingIndicator: const CircularProgressIndicator(),
                style: const ApplePayButtonStyle(
                  theme: ApplePayButtonTheme.whiteOutline,
                  type: ApplePayButtonType.book,
                ),
                width: 300,
                height: 56,
                onPaymentResult: (paymentResult) {
                  Navigator.pop(context);
                  DialogBuilder.showPaymentResultDialog(paymentResult, context);
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

  ApplePayConfiguration _createApplePayConfiguration() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ApplePayConfiguration(
      merchantId: Config.merchantId,
      merchantName: Config.merchantName,
      allowOnboarding: true,
      applePaySummaryItems: [
        ApplePaySummaryItem(
          label: "Product A",
          amount: Amount(value: 5000, currency: "EUR"),
          type: ApplePaySummaryItemType.definite,
        ),
        ApplePaySummaryItem(
          label: "Product B",
          amount: Amount(value: 2500, currency: "EUR"),
          type: ApplePaySummaryItemType.definite,
        ),
        ApplePaySummaryItem(
          label: "Discount",
          amount: Amount(value: -1000, currency: "EUR"),
          type: ApplePaySummaryItemType.definite,
        ),
        ApplePaySummaryItem(
          label: "Total",
          amount: Config.amount,
          type: ApplePaySummaryItemType.definite,
        ),
      ],
      requiredShippingContactFields: [
        ApplePayContactField.name,
        ApplePayContactField.postalAddress,
      ],
      shippingContact: ApplePayContact(
        givenName: "John",
        familyName: "Doe",
        addressLines: ["Simon Carmiggeltstraat 6"],
        postalCode: "1011 DJ",
        city: "Amsterdam",
        country: "Netherlands",
      ),
      applePayShippingType: ApplePayShippingType.shipping,
      allowShippingContactEditing: true,
      shippingMethods: [
        ApplePayShippingMethod(
          label: "Standard shipping",
          detail: "DHL",
          amount: Amount(value: 1000, currency: "EUR"),
          identifier: "identifier 1",
          startDate: today.add(const Duration(days: 2)),
          endDate: today.add(const Duration(days: 5)),
        ),
        ApplePayShippingMethod(
          label: "Store pick up",
          detail: "Weekdays, from 9:00 am to 6:00 pm",
          amount: Amount(value: 0, currency: "EUR"),
          identifier: "identifier 2",
        ),
      ],
    );
  }

  Map<String, dynamic> _extractPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    return paymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == "applepay",
      orElse: () => throw Exception("Apple pay payment method not provided"),
    );
  }
}
