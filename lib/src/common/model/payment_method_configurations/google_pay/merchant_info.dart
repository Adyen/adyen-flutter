class MerchantInfo {
  final String? merchantName;
  final String? merchantId;

  const MerchantInfo({
    this.merchantName,
    this.merchantId,
  });

  @override
  String toString() =>
      'MerchantInfo(merchantName: $merchantName, merchantId: $merchantId)';
}
