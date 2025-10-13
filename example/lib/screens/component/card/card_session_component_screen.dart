// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/extensions/card_configuration_extension.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/repositories/config_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CardSessionComponentScreen extends StatelessWidget {
  const CardSessionComponentScreen({
    required this.repository,
    required this.configRepository,
    super.key,
  });

  final AdyenCardComponentRepository repository;
  final ConfigRepository configRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adyen card component')),
      body: SafeArea(
        child: FutureBuilder<_CardComponentData>(
          future: _loadCardComponentData(),
          builder: (
            BuildContext context,
            AsyncSnapshot<_CardComponentData> snapshot,
          ) {
            if (snapshot.hasData) {
              final _CardComponentData checkoutData = snapshot.data!;
              final paymentMethod = _extractPaymentMethod(
                  checkoutData.sessionCheckout.paymentMethods);
              return SingleChildScrollView(
                child: Column(
                  children: [
                    AdyenCardComponent(
                      configuration: checkoutData.cardComponentConfiguration,
                      paymentMethod: paymentMethod,
                      checkout: checkoutData.sessionCheckout,
                      onPaymentResult: (paymentResult) async {
                        Navigator.pop(context);
                        DialogBuilder.showPaymentResultDialog(
                            paymentResult, context);
                      },
                    ),
                    Container(height: 800),
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

  Future<_CardComponentData> _loadCardComponentData() async {
    final cardConfiguration = await configRepository.loadCardConfiguration();
    final cardComponentConfiguration = CardComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      cardConfiguration: cardConfiguration.copyWith(
        onBinLookup: _onBinLookup,
        onBinValue: _onBinValue,
      ),
    );

    final sessionCheckout =
        await repository.createSessionCheckout(cardComponentConfiguration);

    return _CardComponentData(
      sessionCheckout: sessionCheckout,
      cardComponentConfiguration: cardComponentConfiguration,
    );
  }

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

  void _onBinLookup(List<BinLookupData> binLookupDataList) {
    // Bin lookup data based on bin value input. Supports co-branded cards.
    // for (final binLookupData in binLookupDataList) {
    //   debugPrint("Bin lookup data: brand:${binLookupData.brand}");
    // }
  }

  void _onBinValue(String binValue) {
    // Bin value entered by the shopper.
    // debugPrint("Bin value: $binValue");
  }
}

class _CardComponentData {
  final SessionCheckout sessionCheckout;
  final CardComponentConfiguration cardComponentConfiguration;

  _CardComponentData({
    required this.sessionCheckout,
    required this.cardComponentConfiguration,
  });
}
