// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CardAdvancedComponentScreen extends StatelessWidget {
  const CardAdvancedComponentScreen({
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
        holderNameRequired: true,
        addressMode: AddressMode.full,
        cardCallbacks: CardCallbacks(
          onBinLookup: _onBinLookup,
          onBinValue: _onBinValue,
        ),
      ),
    );

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
                        cardComponentConfiguration,
                        snapshot.data!,
                        context,
                      ),
                      Container(height: 600, color: const Color(0xFFEDEDED)),
                    ],
                  ),
                );
              }
            },
          ),
        ));
  }

  Widget _buildCardWidget(
    CardComponentConfiguration cardComponentConfiguration,
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
