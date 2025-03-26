import 'package:adyen_checkout/adyen_checkout.dart';

class CardModel {
  final String? cardNumber;
  final String? expiryMoth;
  final String? expiryYear;
  final CardNumberValidationResult? cardNumberValidationResult;
  final CardExpiryDateValidationResult? cardExpiryDateValidationResult;
  final CardSecurityCodeValidationResult? cardSecurityCodeValidationResult;

  CardModel({
    this.cardNumber,
    this.expiryMoth,
    this.expiryYear,
    this.cardNumberValidationResult,
    this.cardExpiryDateValidationResult,
    this.cardSecurityCodeValidationResult,
  });

  CardModel copyWith({
    String? cardNumber,
    String? expiryMoth,
    String? expiryYear,
    CardNumberValidationResult? cardNumberValidationResult,
    CardExpiryDateValidationResult? cardExpiryDateValidationResult,
    CardSecurityCodeValidationResult? cardSecurityCodeValidationResult,
  }) {
    return CardModel(
      cardNumber: cardNumber ?? this.cardNumber,
      expiryMoth: expiryMoth ?? this.expiryMoth,
      expiryYear: expiryYear ?? this.expiryYear,
      cardNumberValidationResult: cardNumberValidationResult ?? this.cardNumberValidationResult,
      cardExpiryDateValidationResult: cardExpiryDateValidationResult ?? this.cardExpiryDateValidationResult,
      cardSecurityCodeValidationResult: cardSecurityCodeValidationResult ?? this.cardSecurityCodeValidationResult,
    );
  }
}
