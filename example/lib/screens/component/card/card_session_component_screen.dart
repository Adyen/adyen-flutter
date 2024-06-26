// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CardSessionComponentScreen extends StatelessWidget {
  CardSessionComponentScreen({
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
    cardConfiguration: const CardConfiguration(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen card component')),
      body: SafeArea(
        child: FutureBuilder(
          future: _getSessionCheckout(),
          builder:
              (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
            if (snapshot.hasData) {
              final SessionCheckout sessionCheckout = snapshot.data!;
              final paymentMethod =
                  _extractPaymentMethod(sessionCheckout.paymentMethods);
              return SingleChildScrollView(
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
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }

  Future<SessionCheckout> _getSessionCheckout() async {
    final sessionResponse = await repository.fetchSession();
    final sessionCheckout = await AdyenCheckout.session.create(
      sessionId: sessionResponse.id,
      sessionData: sessionResponse.sessionData,
      configuration: cardComponentConfiguration,
    );

    return sessionCheckout;
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
}
