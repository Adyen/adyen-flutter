class UnencryptedCard {
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvc;

  UnencryptedCard({
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvc,
  });

  @override
  String toString() {
    return 'UnencryptedCard('
        'cardNumber: $cardNumber, '
        'expiryMonth: $expiryMonth, '
        'expiryYear: $expiryYear, '
        'cvc: $cvc)';
  }
}
