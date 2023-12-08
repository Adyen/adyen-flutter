import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:flutter/material.dart';

class DropInScreen extends StatefulWidget {
  const DropInScreen({
    required this.repository,
    required this.adyenCheckout,
    super.key,
  });

  final AdyenCheckout adyenCheckout;
  final AdyenDropInRepository repository;

  @override
  State<DropInScreen> createState() => _DropInScreenState();
}

class _DropInScreenState extends State<DropInScreen> {
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
                onPressed: () => startDropInSessions(),
                child: const Text("DropIn sessions"),
              ),
              TextButton(
                onPressed: () => startDropInAdvancedFlow(),
                child: const Text("DropIn advanced flow"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> startDropInSessions() async {
    final SessionResponseNetworkModel sessionResponse =
        await widget.repository.fetchSession();
    final DropInConfiguration dropInConfiguration =
        await _createDropInConfiguration();
    final Session session = Session(
      id: sessionResponse.id,
      sessionData: sessionResponse.sessionData,
      paymentMethodsJson: "",
    );

    final PaymentResult paymentResult = await widget.adyenCheckout.startPayment(
      paymentFlow: DropInSessionFlow(
        dropInConfiguration: dropInConfiguration,
        session: session,
      ),
    );

    _showPaymentResultDialog(paymentResult);
  }

  Future<void> startDropInAdvancedFlow() async {
    final paymentMethodsResponse =
        await widget.repository.fetchPaymentMethods();
    final dropInConfiguration = await _createDropInConfiguration();

    final paymentResult = await widget.adyenCheckout.startPayment(
      paymentFlow: DropInAdvancedFlow(
        dropInConfiguration: dropInConfiguration,
        paymentMethodsResponse: paymentMethodsResponse,
        postPayments: widget.repository.postPayments,
        postPaymentsDetails: widget.repository.postPaymentsDetails,
      ),
    );

    _showPaymentResultDialog(paymentResult);
  }

  Future<DropInConfiguration> _createDropInConfiguration() async {
    const CardConfiguration cardsConfiguration = CardConfiguration(
      showStorePaymentField: false,
    );

    const ApplePayConfiguration applePayConfiguration = ApplePayConfiguration(
      merchantId: Config.merchantAccount,
      merchantName: Config.merchantName,
    );

    const GooglePayConfiguration googlePayConfiguration =
        GooglePayConfiguration(
      googlePayEnvironment: GooglePayEnvironment.test,
      shippingAddressRequired: true,
      billingAddressRequired: true,
    );

    final CashAppPayConfiguration cashAppPayConfiguration =
        await _createCashAppPayConfiguration();

    final StoredPaymentMethodConfiguration storedPaymentMethodConfiguration =
        StoredPaymentMethodConfiguration(
      showPreselectedStoredPaymentMethod: false,
      isRemoveStoredPaymentMethodEnabled: true,
      deleteStoredPaymentMethodCallback:
          widget.repository.deleteStoredPaymentMethod,
    );

    final DropInConfiguration dropInConfiguration = DropInConfiguration(
      environment: Environment.test,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      amount: Config.amount,
      cardConfiguration: cardsConfiguration,
      applePayConfiguration: applePayConfiguration,
      googlePayConfiguration: googlePayConfiguration,
      cashAppPayConfiguration: cashAppPayConfiguration,
      storedPaymentMethodConfiguration: storedPaymentMethodConfiguration,
    );

    return dropInConfiguration;
  }

  //To support CashAppPay please add "pod 'Adyen/CashAppPay'" to your Podfile.
  Future<CashAppPayConfiguration> _createCashAppPayConfiguration() async {
    return CashAppPayConfiguration(
      CashAppPayEnvironment.sandbox,
      await widget.repository.determineBaseReturnUrl(),
    );
  }

  void _showPaymentResultDialog(PaymentResult paymentResult) async {
    String title = "";
    String message = "";
    switch (paymentResult) {
      case PaymentAdvancedFlowFinished():
        title = "Finished";
        message = "Result code: ${paymentResult.resultCode}";
      case PaymentSessionFinished():
        title = "Finished";
        message = "Result code: ${paymentResult.resultCode}";
      case PaymentCancelledByUser():
        title = "Cancelled by user";
        message = "Drop-in cancelled by user";
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
                  textStyle: Theme.of(context).textTheme.labelLarge),
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
