// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
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
                onPressed: () => Navigator.pushNamed(
                    context, "/cardAdvancedComponentScreen"),
                child: const Text("Card component advanced"),
              ),
            ],
          ),
        ),
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
        shopperLocale: Config.shopperLocale,
        cardConfiguration: const CardConfiguration(),
      );

      final sessionCheckout = await AdyenCheckout.session.create(
        sessionId: sessionResponse.id,
        sessionData: sessionResponse.sessionData,
        configuration: cardComponentConfiguration,
      );

      final paymentMethod =
          _extractPaymentMethod(sessionCheckout.paymentMethods);

      // ignore: use_build_context_synchronously
      if (mounted) {
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
                        DialogBuilder.showPaymentResultDialog(
                            paymentResult, context);
                      },
                    ),
                  ),
                ],
              )),
            );
          },
        );
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Map<String, dynamic> _extractPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    List paymentMethodList = paymentMethods["paymentMethods"] as List;
    Map<String, dynamic> paymentMethod = paymentMethodList
        .firstWhere((paymentMethod) => paymentMethod["type"] == "scheme");

    List storedPaymentMethodList =
        paymentMethods.containsKey("storedPaymentMethods")
            ? paymentMethods["storedPaymentMethods"] as List
            : [];
    Map<String, dynamic> storedPaymentMethod =
        storedPaymentMethodList.firstOrNull ?? <String, String>{};

    return paymentMethod;
  }
}
