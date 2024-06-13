// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CardAdvancedComponentScreen extends StatelessWidget {
  CardAdvancedComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenCardComponentRepository repository;
  final CardComponentConfiguration cardComponentConfiguration =
      CardComponentConfiguration(
    environment: Config.environment,
    clientKey: Config.clientKey,
    countryCode: Config.countryCode,
    shopperLocale: Config.shopperLocale,
    cardConfiguration: const CardConfiguration(
      holderNameRequired: true,
      addressMode: AddressMode.postalCode,
      showStorePaymentField: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Adyen card component')),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: repository.fetchPaymentMethods(),
            builder: (BuildContext context,
                AsyncSnapshot<Map<String, dynamic>> snapshot) {
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
    Map<String, dynamic> paymentMethods,
    BuildContext context,
  ) {
    final paymentMethod = extractPaymentMethod(paymentMethods);
    final advancedCheckout = AdvancedCheckout(
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

  Map<String, dynamic> extractPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    List paymentMethodList = paymentMethods["paymentMethods"] as List;
    Map<String, dynamic>? paymentMethod = paymentMethodList
        .firstWhereOrNull((paymentMethod) => paymentMethod["type"] == "scheme");

    List storedPaymentMethodList =
        paymentMethods.containsKey("storedPaymentMethods")
            ? paymentMethods["storedPaymentMethods"] as List
            : [];
    Map<String, dynamic>? storedPaymentMethod =
        storedPaymentMethodList.firstOrNull;

    return paymentMethod ?? <String, String>{};
  }
}
