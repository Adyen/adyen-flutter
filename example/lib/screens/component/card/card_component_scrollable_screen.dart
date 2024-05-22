// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CardComponentScrollableScreen extends StatelessWidget {
  const CardComponentScrollableScreen({
    required this.repository,
    super.key,
  });

  final AdyenCardComponentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Adyen card component')),
        body: SafeArea(
          child: FutureBuilder<String>(
            future: repository.fetchPaymentMethods(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.data == null) {
                return const SizedBox.shrink();
              } else {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildCardWidget(
                        snapshot.data!,
                        context,
                      ),
                      Container(height: 200, color: Colors.yellow),
                      Container(height: 200, color: Colors.blue),
                      Container(height: 200, color: Colors.green),
                      Container(height: 200, color: Colors.purple),
                    ],
                  ),
                );
              }
            },
          ),
        ));
  }

  Widget _buildCardWidget(
    String paymentMethods,
    BuildContext context,
  ) {
    final paymentMethod = extractPaymentMethod(paymentMethods);
    final cardComponentConfiguration = CardComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      shopperLocale: Config.shopperLocale,
      cardConfiguration: const CardConfiguration(),
    );
    final advancedCheckout = AdvancedCheckoutPreview(
      onSubmit: repository.onSubmit,
      onAdditionalDetails: repository.onAdditionalDetails,
    );

    return AdyenCardComponent(
      configuration: cardComponentConfiguration,
      paymentMethod: paymentMethod,
      checkout: advancedCheckout,
      onPaymentResult: (paymentResult) async {
        Navigator.pop(context);
        DialogBuilder.showPaymentResultDialog(paymentResult, context);
      },
    );
  }

  Map<String, dynamic> extractPaymentMethod(String paymentMethods) {
    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    List paymentMethodList = jsonPaymentMethods["paymentMethods"] as List;
    Map<String, dynamic>? paymentMethod = paymentMethodList
        .firstWhereOrNull((paymentMethod) => paymentMethod["type"] == "scheme");

    List storedPaymentMethodList =
        jsonPaymentMethods.containsKey("storedPaymentMethods")
            ? jsonPaymentMethods["storedPaymentMethods"] as List
            : [];
    Map<String, dynamic>? storedPaymentMethod =
        storedPaymentMethodList.firstOrNull;

    return paymentMethod ?? <String, String>{};
  }
}
