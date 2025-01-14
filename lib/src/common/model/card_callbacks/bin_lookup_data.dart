class BinLookupData {
  final String brand;
  final bool isReliable;
  final String? paymentMethodVariant;

  BinLookupData({
    required this.brand,
    required this.isReliable,
    this.paymentMethodVariant,
  });
}
