const Object _sentinel = Object();

class CardState {
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? securityCode;
  final bool loading;
  final bool? isCardNumberValid;
  final bool? isExpiryDateValid;
  final bool? isSecurityCodeValid;
  final List<String>? relatedCardBrands;
  final bool isInputValid;

  CardState({
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.securityCode,
    this.loading = false,
    this.isCardNumberValid,
    this.isExpiryDateValid,
    this.isSecurityCodeValid,
    this.relatedCardBrands,
    this.isInputValid = false,
  });

  CardState copyWith({
    String? cardNumber,
    String? expiryMonth,
    String? expiryYear,
    String? securityCode,
    bool? loading,
    Object? isCardNumberValid = _sentinel,
    Object? isExpiryDateValid = _sentinel,
    Object? isSecurityCodeValid = _sentinel,
    List<String>? relatedCardBrands,
  }) {
    final validCardNumber = identical(isCardNumberValid, _sentinel)
        ? this.isCardNumberValid
        : isCardNumberValid as bool?;
    final validExpiryDate = identical(isExpiryDateValid, _sentinel)
        ? this.isExpiryDateValid
        : isExpiryDateValid as bool?;
    final validSecurityCode = identical(isSecurityCodeValid, _sentinel)
        ? this.isSecurityCodeValid
        : isSecurityCodeValid as bool?;
    final isInputValid = (validCardNumber == true) &&
        (validExpiryDate == true) &&
        (validSecurityCode == true);

    return CardState(
      cardNumber: cardNumber ?? this.cardNumber,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      securityCode: securityCode ?? this.securityCode,
      loading: loading ?? this.loading,
      isCardNumberValid: validCardNumber,
      isExpiryDateValid: validExpiryDate,
      isSecurityCodeValid: validSecurityCode,
      isInputValid: isInputValid,
      relatedCardBrands: relatedCardBrands ?? this.relatedCardBrands,
    );
  }
}
