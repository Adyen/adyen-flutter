// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class ApplePaySessionComponentScreen extends StatelessWidget {
  const ApplePaySessionComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenApplePayComponentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adyen Apple Pay component')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildAdyenApplePaySessionComponent()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdyenApplePaySessionComponent() {
    final ApplePayComponentConfiguration applePayComponentConfiguration =
        ApplePayComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      applePayConfiguration: _createApplePayConfiguration(),
    );

    return FutureBuilder<SessionCheckout>(
      future: repository.createSessionCheckout(applePayComponentConfiguration),
      builder: (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
        if (snapshot.hasData) {
          final SessionCheckout sessionCheckout = snapshot.data!;
          final paymentMethod =
              _extractPaymentMethod(sessionCheckout.paymentMethods);

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
                width: 200,
                height: 48,
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
    return ApplePayConfiguration(
      merchantId: Config.merchantId,
      merchantName: Config.merchantName,
      allowOnboarding: true,
      applePaySummaryItems: _buildApplePaySummaryItems(),
      onAuthorize: _onAuthorize,
    );
  }

  Future<ApplePayAuthorizationResult> _onAuthorize(
    ApplePayAuthorizedPayment payment,
  ) async {
    debugPrint('onAuthorize: $payment');
    final ApplePayAuthorizationResult authorizationResult;
    if (payment.shippingContact?.postalCode == "") {
      authorizationResult = ApplePayAuthorizationResult.failure(
        errors: [
          ApplePayPaymentError(
            type: ApplePayPaymentErrorType.shippingAddress,
            field: ApplePayContactField.postalAddress,
            localizedDescription: "Postal code is required.",
          ),
        ],
      );
    } else {
      authorizationResult = const ApplePayAuthorizationResult.success();
    }
    return authorizationResult;
  }

  List<ApplePaySummaryItem> _buildApplePaySummaryItems() {
    const productAAmount = 8000;
    const productBAmount = 2295;
    const shippingAmount = 1000;

    return [
      ApplePaySummaryItem(
        label: "Product A",
        amount: Amount(value: productAAmount, currency: Config.amount.currency),
        type: ApplePaySummaryItemType.definite,
      ),
      ApplePaySummaryItem(
        label: "Product B",
        amount: Amount(value: productBAmount, currency: Config.amount.currency),
        type: ApplePaySummaryItemType.definite,
      ),
      ApplePaySummaryItem(
        label: "Shipping",
        amount: Amount(value: shippingAmount, currency: Config.amount.currency),
        type: ApplePaySummaryItemType.definite,
      ),
      ApplePaySummaryItem(
        label: "Total",
        amount: Config.amount, //In sessions, the amount cannot be changed
        type: ApplePaySummaryItemType.definite,
      ),
    ];
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
