import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/screens/cse/card_model.dart';
import 'package:flutter/widgets.dart';

class CardModelNotifier extends ValueNotifier<CardModel> {
  CardModelNotifier(super.value);

  final formKey = GlobalKey<FormState>();

  Future<void> updateCardNumber(String cardNumber) async {
    final String cardNumberTrimmed = cardNumber.trim();
    final CardNumberValidationResult cardNumberValidationResult =
        cardNumber.isEmpty
            ? ValidCardNumber()
            : await _validateCardNumberInput(cardNumberTrimmed);

    value = value.copyWith(
      cardNumberValidationResult: cardNumberValidationResult,
      cardNumber: cardNumberTrimmed,
    );
  }

  Future<void> updateExpiryDate(String expiryDate) async {
    final index = expiryDate.indexOf('/');
    if (index == -1) {
      return;
    }

    final String expiryMonth = expiryDate.substring(0, index);
    final String expiryYear = expiryDate.substring(index + 1);
    final CardExpiryDateValidationResult cardExpiryDateValidationResult =
        await _validateExpiryDate(expiryMonth, expiryYear);
    value = value.copyWith(
      expiryMoth: expiryMonth,
      expiryYear: expiryYear,
      cardExpiryDateValidationResult: cardExpiryDateValidationResult,
    );
  }

  Future<void> updateSecurityCode(String securityCode) async {}

  void validateCardNumber() {
    formKey.currentState?.validate();
  }

  Future<CardNumberValidationResult> _validateCardNumberInput(
      String cardNumber) async {
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

    return cardNumberValidationResult;
  }

  Future<CardExpiryDateValidationResult> _validateExpiryDate(
    String expiryMonth,
    String expiryYear,
  ) async {
    final CardExpiryDateValidationResult cardExpiryDateValidationResult =
        await AdyenCheckout.instance.validateCardExpiryDate(
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
    return cardExpiryDateValidationResult;
  }

  Future<void> _validateCardInput(UnencryptedCard unencryptedCard) async {
    final CardSecurityCodeValidationResult cardSecurityCodeValidationResult =
        await AdyenCheckout.instance.validateCardSecurityCode(
      securityCode: unencryptedCard.cvc ?? "",
      cardBrand: "amex",
    );
    switch (cardSecurityCodeValidationResult) {
      case ValidCardSecurityCode():
        debugPrint("Card security code is valid.");
      case InvalidCardSecurityCode():
        debugPrint("Card security code is invalid.");
    }
  }
}
