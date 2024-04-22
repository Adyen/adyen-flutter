import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter/material.dart';

class CseScreen extends StatelessWidget {
  CseScreen({
    super.key,
  });

  final UnencryptedCard unencryptedCard = UnencryptedCard(
    cardNumber: "1234123412341234",
    expiryMonth: "12",
    expiryYear: "34",
    cvc: "737",
  );
  final String publicKey = "PUBLIC_KEY";

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
                  onPressed: encryptCardToContentBlock,
                  child: const Text("Encrypt card (content block)")),
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
      final EncryptedCard encryptedCard =
          await AdyenCheckout.instance.encryptCard(unencryptedCard, publicKey);
      debugPrint(encryptedCard.toString());
    } catch (exception) {
      debugPrint(exception.toString());
    }
  }

  Future<void> encryptCardToContentBlock() async {
    try {
      final String encryptedCard =
          await AdyenCheckout.instance.encrypt(unencryptedCard, publicKey);
      debugPrint(encryptedCard.toString());
    } catch (exception) {
      debugPrint(exception.toString());
    }
  }

  Future<void> encryptBin() async {
    try {
      const bin = "123412341234";
      final String encryptedCard =
          await AdyenCheckout.instance.encryptBin(bin, publicKey);
      debugPrint(encryptedCard.toString());
    } catch (exception) {
      debugPrint(exception.toString());
    }
  }
}
