import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/repositories/adyen_sessions_repository.dart';
import 'package:flutter/material.dart';

import '../config.dart';

class FirstRoute extends StatelessWidget {
  const FirstRoute({required this.repository, super.key});

  final AdyenSessionsRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Adyen card component'),
        ),
        body: SafeArea(
          child: FutureBuilder<String>(
            future: repository.fetchPaymentMethods(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.data == null) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      Container(height: 200, color: Colors.blue),
                      buildCardWidget(
                        snapshot.data!,
                        context,
                        repository,
                      ),
                      Container(height: 200, color: Colors.yellow),
                      Container(height: 200, color: Colors.green),
                    ],
                  ),
                );
              }
            },
          ),
        ));
  }
}

Widget buildCardWidget(
  String paymentMethods,
  BuildContext context,
  AdyenSessionsRepository repository,
) {
  final cardComponentConfiguration = CardComponentConfiguration(
    environment: Config.environment,
    clientKey: Config.clientKey,
    countryCode: Config.countryCode,
    amount: Config.amount,
    shopperLocale: Config.shopperLocale,
    cardConfiguration: const CardConfiguration(showStorePaymentField: false),
  );

  return AdyenCardComponentWidget(
    componentPaymentFlow: CardComponentAdvancedFlow(
      cardComponentConfiguration: cardComponentConfiguration,
      paymentMethods: paymentMethods,
      onPayments: repository.postPayments,
      onPaymentsDetails: repository.postPaymentsDetails,
    ),
    onPaymentResult: (event) async {
      //Navigator.pop(context);
      _dialogBuilder(context, event);
    },
  );
}

_dialogBuilder(BuildContext context, PaymentResult paymentResult) {
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
