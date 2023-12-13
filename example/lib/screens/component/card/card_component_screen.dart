// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/screens/component/card/card_component_scrollable_screen.dart';
import 'package:flutter/material.dart';

class CardComponentScreen extends StatefulWidget {
  const CardComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenCardComponentRepository repository;

  @override
  State<CardComponentScreen> createState() => _CardComponentScreenState();
}

class _CardComponentScreenState extends State<CardComponentScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen card component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => showCardComponentBottomSheet(),
                child: const Text("Card component session"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    _buildCardComponentAdvancedFlowRoute(),
                  );
                },
                child: const Text("Card component advanced flow"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MaterialPageRoute<dynamic> _buildCardComponentAdvancedFlowRoute() {
    return MaterialPageRoute(
      builder: (context) => CardComponentScrollableScreen(
        repository: widget.repository,
      ),
    );
  }

  void showCardComponentBottomSheet() async {
    try {
      final sessionResponse = await widget.repository.fetchSession();
      final cardComponentConfiguration = CardComponentConfiguration(
        environment: Config.environment,
        clientKey: Config.clientKey,
        countryCode: Config.countryCode,
        amount: Config.amount,
        shopperLocale: Config.shopperLocale,
        cardConfiguration: const CardConfiguration(),
      );

      final sessionCheckout = await AdyenCheckout.session.create(
        sessionId: sessionResponse.id,
        sessionData: sessionResponse.sessionData,
        configuration: cardComponentConfiguration,
      );

      final paymentMethod =
          extractPaymentMethod(sessionCheckout.paymentMethodsJson);

      // ignore: use_build_context_synchronously
      return showModalBottomSheet(
        context: context,
        isDismissible: false,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
                child: Column(
              children: [
                Container(height: 8),
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey),
                ),
                Container(height: 8),
                Container(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: AdyenCardComponent(
                    configuration: cardComponentConfiguration,
                    paymentMethod: paymentMethod,
                    checkout: sessionCheckout,
                    onPaymentResult: (paymentResult) async {
                      Navigator.pop(context);
                      _dialogBuilder(paymentResult);
                    },
                  ),
                ),
              ],
            )),
          );
        },
      );
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Map<String, dynamic> extractPaymentMethod(String paymentMethods) {
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

  _dialogBuilder(PaymentResult paymentResult) {
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
