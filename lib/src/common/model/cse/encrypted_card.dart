class EncryptedCard {
  final String? encryptedCardNumber;
  final String? encryptedExpiryMonth;
  final String? encryptedExpiryYear;
  final String? encryptedSecurityCode;

  EncryptedCard({
    this.encryptedCardNumber,
    this.encryptedExpiryMonth,
    this.encryptedExpiryYear,
    this.encryptedSecurityCode,
  });

  @override
  String toString() {
    return 'EncryptedCard('
        'encryptedCardNumber: $encryptedCardNumber, '
        'encryptedExpiryMonth: $encryptedExpiryMonth, '
        'encryptedExpiryYear: $encryptedExpiryYear, '
        'encryptedSecurityCode: $encryptedSecurityCode)';
  }
}
