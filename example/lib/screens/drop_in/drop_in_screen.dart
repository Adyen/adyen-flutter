import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class DropInScreen extends StatelessWidget {
  const DropInScreen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen Drop-in')),
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
                child: const Text("Drop-in advanced"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> startDropInSessions(BuildContext context) async {
    try {
      final SessionResponseNetworkModel sessionResponse =
          await repository.fetchSession();
      final DropInConfiguration dropInConfiguration =
          await _createDropInConfiguration();

      final SessionCheckout sessionCheckout =
          await AdyenCheckout.session.create(
        sessionId: sessionResponse.id,
        sessionData: sessionResponse.sessionData,
        configuration: dropInConfiguration,
      );

      final PaymentResult paymentResult =
          await AdyenCheckout.session.startDropIn(
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
      final paymentMethodsResponse = await repository.fetchPaymentMethods();
      final dropInConfiguration = await _createDropInConfiguration();
      final advancedCheckout = AdvancedCheckout(
        onSubmit: repository.onSubmit,
        onAdditionalDetails: repository.onAdditionalDetails,
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

  Future<DropInConfiguration> _createDropInConfiguration() async {
    const CardConfiguration cardsConfiguration = CardConfiguration();

    ApplePayConfiguration applePayConfiguration = ApplePayConfiguration(
      merchantId: Config.merchantId,
      merchantName: Config.merchantName,
    );

    const GooglePayConfiguration googlePayConfiguration =
        GooglePayConfiguration(
      googlePayEnvironment: Config.googlePayEnvironment,
      shippingAddressRequired: true,
      billingAddressRequired: true,
    );

    //To support CashAppPay please add "pod 'Adyen/CashAppPay'" to your Podfile.
    final String returnUrl = await repository.determineBaseReturnUrl();
    final CashAppPayConfiguration cashAppPayConfiguration =
        CashAppPayConfiguration(
      cashAppPayEnvironment: CashAppPayEnvironment.sandbox,
      returnUrl: returnUrl,
    );

    final StoredPaymentMethodConfiguration storedPaymentMethodConfiguration =
        StoredPaymentMethodConfiguration(
      showPreselectedStoredPaymentMethod: false,
      isRemoveStoredPaymentMethodEnabled: true,
      deleteStoredPaymentMethodCallback: repository.deleteStoredPaymentMethod,
    );

    final DropInConfiguration dropInConfiguration = DropInConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      amount: Config.amount,
      cardConfiguration: cardsConfiguration,
      applePayConfiguration: applePayConfiguration,
      googlePayConfiguration: googlePayConfiguration,
      cashAppPayConfiguration: cashAppPayConfiguration,
      storedPaymentMethodConfiguration: storedPaymentMethodConfiguration,
      paymentMethodNames: {
        "scheme": "Credit card",
      },
    );

    return dropInConfiguration;
  }
}
