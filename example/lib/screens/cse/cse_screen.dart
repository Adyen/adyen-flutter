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
      const String cardNumber = "3714 4963 5398 431";
      const String expiryMonth = "03";
      const String expiryYear = "2030";

      final UnencryptedCard unencryptedCard = UnencryptedCard(
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvc: "7373",
      );

      final CardNumberValidationResult cardNumberValidationResult =
          await AdyenCheckout.instance.validateCardNumber(
        cardNumber: cardNumber,
        enableLuhnCheck: true,
      );

      switch (cardNumberValidationResult) {
        case ValidCardNumber():
          debugPrint("Card number is valid.");
        case InvalidCardNumber it:
          switch (it) {
            case InvalidCardNumberOtherReason _:
              debugPrint("Card number is invalid due to other reason.");
          }
      }

      final CardExpiryDateValidationResult cardExpiryDateValidationResult =
          await AdyenCheckout.instance.validateCardExpireDate(
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
      );

      switch (cardExpiryDateValidationResult) {
        case ValidCardExpiryDate():
          debugPrint("Card expire date is valid.");
        case InvalidCardExpiryDate it:
          switch (it) {
            case InvalidCardExpiryDateOtherReason _:
              debugPrint("Card expire date is invalid due to other reason.");
          }
      }

      final EncryptedCard encryptedCard = await AdyenCheckout.instance
          .encryptCard(unencryptedCard, Config.publicKey);
      final Map<String, dynamic> paymentsResponse =
          await repository.makePayment(encryptedCard);
      if (paymentsResponse.containsKey("action")) {
        final ActionComponentConfiguration actionComponentConfiguration =
            ActionComponentConfiguration(
          environment: Config.environment,
          clientKey: Config.clientKey,
          shopperLocale: Config.shopperLocale,
        );
        final ActionResult actionResultDetails =
            await AdyenCheckout.instance.handleAction(
          actionComponentConfiguration,
          paymentsResponse["action"],
        );
        switch (actionResultDetails) {
          case ActionSuccess it:
            debugPrint("Action result: ${it.data}");
          case ActionError it:
            debugPrint("Action error: ${it.errorMessage}");
        }
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
