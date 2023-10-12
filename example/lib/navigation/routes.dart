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
          title: const Text('Card component'),
        ),
        body: FutureBuilder<String>(
          future: repository.fetchPaymentMethods(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return buildCardWidget(snapshot, context);
              return SingleChildScrollView(
                physics: ClampingScrollPhysics(),

                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: FlutterLogo(size: 128),
                    ),
                    const Text("This is a Flutter view"),
                    SizedBox(
                      height: 350,
                      child: buildCardWidget(snapshot, context),
                    ),
                    Container(height: 300, width: 200, color: Colors.pink,),
                    Container(height: 500, width: 400, color: Colors.yellow,)

                  ],
                ),
              );
            }
          },
        ));
  }

  Widget buildCardWidget(AsyncSnapshot<String> snapshot, BuildContext context) {
    return SizedBox(
      height: 550,
      child: CardWidget(
                        paymentMethods: snapshot.data!,
                        clientKey: Config.clientKey,
                        onSubmit: repository.postPayments,
                        onResult: (event) async {
                          _dialogBuilder(context, event);
                        },
                      ),
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

}
