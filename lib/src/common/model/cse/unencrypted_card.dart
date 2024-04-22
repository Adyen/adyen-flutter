class UnencryptedCard {
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvc;
  final String? cardHolderName;

  UnencryptedCard({
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvc,
    this.cardHolderName,
  });
}
