import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:flutter/material.dart';

class CseScreen extends StatelessWidget {
  CseScreen({
    super.key,
  });

  final String publicKey = Config.publicKey;

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
                  onPressed: encryptCard, child: const Text("Encrypt card")),
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
        cardNumber: "5555555555554444",
        expiryMonth: "03",
        expiryYear: "2030",
        cvc: "737",
      );
      final EncryptedCard encryptedCard =
          await AdyenCheckout.instance.encryptCard(unencryptedCard, publicKey);
      debugPrint("Encrypted card number: ${encryptedCard.encryptedCardNumber}");
    } catch (exception) {
      debugPrint(exception.toString());
    }
  }

  Future<void> encryptBin() async {
    try {
      const bin = "5555555555554444";
      final String encryptedBin =
          await AdyenCheckout.instance.encryptBin(bin, publicKey);
      debugPrint("Encrypted bin: $encryptedBin");
    } catch (exception) {
      debugPrint(exception.toString());
    }
  }
}
