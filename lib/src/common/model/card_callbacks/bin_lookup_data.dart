class BinLookupData {
  final String? issuingCountryCode;
  final List<BinLookupBrand> brands;

  const BinLookupData({
    this.issuingCountryCode,
    this.brands = const [],
  });

  @override
  String toString() =>
      'BinLookupData(issuingCountryCode: $issuingCountryCode, brands: $brands)';
}

class BinLookupBrand {
  final String brand;
  final bool supported;
  final String? paymentMethodVariant;

  const BinLookupBrand({
    required this.brand,
    required this.supported,
    this.paymentMethodVariant,
  });

  @override
  String toString() =>
      'BinLookupBrand(brand: $brand, supported: $supported, paymentMethodVariant: $paymentMethodVariant)';
}
