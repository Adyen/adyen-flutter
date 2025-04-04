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
      relatedCardBrands: relatedCardBrands ?? this.relatedCardBrands,
    );
  }
}
