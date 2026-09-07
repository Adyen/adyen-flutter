class EncryptedCard {
  final String? encryptedCardNumber;
  final String? encryptedExpiryMonth;
  final String? encryptedExpiryYear;
  final String? encryptedSecurityCode;

  const EncryptedCard({
    this.encryptedCardNumber,
    this.encryptedExpiryMonth,
    this.encryptedExpiryYear,
    this.encryptedSecurityCode,
  });

  @override
  String toString() => 'EncryptedCard(<redacted>)';
}
