class MerchantInfo {
  final String? merchantName;
  final String? merchantId;

  MerchantInfo({
    this.merchantName,
    this.merchantId,
  });

  @override
  String toString() {
    return 'MerchantInfo('
        'merchantName: $merchantName, '
        'merchantId: $merchantId)';
  }
}
