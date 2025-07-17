// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class CardBottomSheetScreen extends StatelessWidget {
  CardBottomSheetScreen({
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
      showStorePaymentField: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card component bottom sheet')),
      body: SafeArea(
        child: Center(
          child: TextButton(
              child: const Text("Show bottom sheet"),
              onPressed: () {
                showModalBottomSheet(
                  isDismissible: false,
                  isScrollControlled: true,
                  context: context,
                  builder: (BuildContext context) {
                    return buildModalBottomSheetContent(context);
                  },
                );
              }),
        ),
      ),
    );
  }

  Widget buildModalBottomSheetContent(BuildContext context) {
    return SafeArea(
        child: Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: FutureBuilder(
        future: repository.fetchPaymentMethods(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasData) {
            final paymentMethod = _extractPaymentMethod(snapshot.data!);
            final advancedCheckout = AdvancedCheckout(
              onSubmit: repository.onSubmit,
              onAdditionalDetails: repository.onAdditionalDetails,
            );

            return Container(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  AdyenCardComponent(
                    configuration: cardComponentConfiguration,
                    paymentMethod: paymentMethod,
                    checkout: advancedCheckout,
                    onPaymentResult: (paymentResult) async {
                      Navigator.pop(context);
                      DialogBuilder.showPaymentResultDialog(
                          paymentResult, context);
                    },
                  ),
                  const Text("Example text")
                ],
              ),
            );
          } else {
            return const SizedBox(
              height: 400,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    ));
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
