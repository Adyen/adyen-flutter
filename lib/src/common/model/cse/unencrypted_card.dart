class UnencryptedCard {
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvc;

  const UnencryptedCard({
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvc,
  });

  @override
  String toString() => 'UnencryptedCard(<redacted>)';
}
