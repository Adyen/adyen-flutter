import 'package:adyen_checkout/adyen_checkout.dart';

class CardState {
  final String? cardNumber;
  final String? expiryMoth;
  final String? expiryYear;
  final String? securityCode;
  final bool? loading;
  final CardNumberValidationResult? cardNumberValidationResult;
  final CardExpiryDateValidationResult? cardExpiryDateValidationResult;
  final CardSecurityCodeValidationResult? cardSecurityCodeValidationResult;
  final List<String>? relatedCardBrands;
  final bool isInputValid;

  CardState({
    this.cardNumber,
    this.expiryMoth,
    this.expiryYear,
    this.securityCode,
    this.loading,
    this.cardNumberValidationResult,
    this.cardExpiryDateValidationResult,
    this.cardSecurityCodeValidationResult,
    this.relatedCardBrands,
    this.isInputValid = false,
  });

  CardState copyWith({
    String? cardNumber,
    String? expiryMoth,
    String? expiryYear,
    String? securityCode,
    bool? loading,
    CardNumberValidationResult? cardNumberValidationResult,
    CardExpiryDateValidationResult? cardExpiryDateValidationResult,
    CardSecurityCodeValidationResult? cardSecurityCodeValidationResult,
    List<String>? relatedCardBrands,
  }) {
    final isInputValid = (cardNumberValidationResult ??
            this.cardNumberValidationResult) is ValidCardNumber &&
        (cardExpiryDateValidationResult ?? this.cardExpiryDateValidationResult)
            is ValidCardExpiryDate &&
        (cardSecurityCodeValidationResult ??
            this.cardSecurityCodeValidationResult) is ValidCardSecurityCode;
    return CardState(
      cardNumber: cardNumber ?? this.cardNumber,
      expiryMoth: expiryMoth ?? this.expiryMoth,
      expiryYear: expiryYear ?? this.expiryYear,
      securityCode: securityCode ?? this.securityCode,
      loading: loading ?? this.loading,
      cardNumberValidationResult:
          cardNumberValidationResult ?? this.cardNumberValidationResult,
      cardExpiryDateValidationResult:
          cardExpiryDateValidationResult ?? this.cardExpiryDateValidationResult,
      cardSecurityCodeValidationResult: cardSecurityCodeValidationResult ??
          this.cardSecurityCodeValidationResult,
      isInputValid: isInputValid,
      relatedCardBrands: relatedCardBrands ?? this.relatedCardBrands,
    );
  }
}
