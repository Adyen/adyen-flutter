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
        'cardNumber: **** **** **** ****, '
        'expiryMonth: **, '
        'expiryYear: ****, '
        'cvc: ***)';
  }
}
