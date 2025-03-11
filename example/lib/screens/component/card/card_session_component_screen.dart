// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CardSessionComponentScreen extends StatelessWidget {
  const CardSessionComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenCardComponentRepository repository;

  @override
  Widget build(BuildContext context) {
    final CardComponentConfiguration cardComponentConfiguration =
        CardComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      cardConfiguration: CardConfiguration(
        onBinLookup: _onBinLookup,
        onBinValue: _onBinValue,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen card component')),
      body: SafeArea(
        child: FutureBuilder(
          future: _getSessionCheckout(cardComponentConfiguration),
          builder:
              (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
            if (snapshot.hasData) {
              final SessionCheckout sessionCheckout = snapshot.data!;
              final paymentMethod =
                  _extractPaymentMethod(sessionCheckout.paymentMethods);
              return SingleChildScrollView(
                child: Column(
                  children: [
                    AdyenCardComponent(
                      configuration: cardComponentConfiguration,
                      paymentMethod: paymentMethod,
                      checkout: sessionCheckout,
                      onPaymentResult: (paymentResult) async {
                        Navigator.pop(context);
                        DialogBuilder.showPaymentResultDialog(
                            paymentResult, context);
                      },
                    ),
                    Container(height: 800, color: const Color(0xFFEDEDED)),
                  ],
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Future<SessionCheckout> _getSessionCheckout(
          CardComponentConfiguration configuration) async =>
      await repository.createSessionCheckout(configuration);

  Map<String, dynamic> _extractPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    List paymentMethodList = paymentMethods["paymentMethods"] as List;
    Map<String, dynamic> paymentMethod = paymentMethodList.firstWhereOrNull(
            (paymentMethod) => paymentMethod["type"] == "scheme") ??
        <String, String>{};

    List storedPaymentMethodList =
        paymentMethods.containsKey("storedPaymentMethods")
            ? paymentMethods["storedPaymentMethods"] as List
            : [];
    Map<String, dynamic> storedPaymentMethod =
        storedPaymentMethodList.firstOrNull ?? <String, String>{};

    return paymentMethod;
  }

  void _onBinLookup(List<BinLookupData> binLookupData) {
    for (var element in binLookupData) {
      debugPrint("Bin lookup data: brand:${element.brand}");
    }
  }

  void _onBinValue(String binValue) {
    debugPrint("Bin value: $binValue");
  }
}
