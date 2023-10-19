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
        backgroundColor: Colors.lightGreen,
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
                  child: Column(
                    children: [
                      const FlutterLogo(size: 128),
                      buildCardWidget(snapshot, context, repository),
                      Container(height: 50),
                      Container(height: 280, color: Colors.blue),
                      const Text(
                          "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."),
                      Container(height: 180, color: Colors.yellow),
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
  AsyncSnapshot<String> snapshot,
  BuildContext context,
  AdyenSessionsRepository repository,
) {
  return AdyenCardWidget(
    paymentMethods: snapshot.data!,
    clientKey: Config.clientKey,
    onSubmit: repository.postPayments,
    onResult: (event) async {
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
