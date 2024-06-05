import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_cse_repository.dart';
import 'package:flutter/material.dart';

class CseScreen extends StatelessWidget {
  const CseScreen({super.key, required this.repository});

  final AdyenCseRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen Client-Side encryption')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: encryptCard,
                  child: const Text("Encrypted card payment")),
              TextButton(
                  onPressed: encryptBin, child: const Text("Encrypt bin"))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> encryptCard() async {
    try {
      final UnencryptedCard unencryptedCard = UnencryptedCard(
        cardNumber: "3714 4963 5398 431",
        expiryMonth: "03",
        expiryYear: "2030",
        cvc: "7373",
      );
      final EncryptedCard encryptedCard = await AdyenCheckout.instance
          .encryptCard(unencryptedCard, Config.publicKey);
      final Map<String, dynamic> paymentsResponse =
          await repository.makePayment(encryptedCard);
      if (paymentsResponse.containsKey("action")) {
        final ActionComponentConfiguration actionComponentConfiguration =
            ActionComponentConfiguration(
          environment: Config.environment,
          clientKey: Config.clientKey,
        );
        final Map<String, dynamic> actionResultDetails =
            await AdyenCheckout.instance.handleAction(
          actionComponentConfiguration,
          paymentsResponse["action"],
        );
        debugPrint("Action result details: $actionResultDetails");
      }
    } catch (exception) {
      debugPrint(exception.toString());
    }
  }

  Future<void> encryptBin() async {
    try {
      const bin = "5555555555554444";
      final String encryptedBin =
          await AdyenCheckout.instance.encryptBin(bin, Config.publicKey);
      debugPrint("Encrypted bin: $encryptedBin");
    } catch (exception) {
      debugPrint(exception.toString());
    }
  }
}
