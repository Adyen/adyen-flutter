class ShippingAddressParameters {
  final List<String>? allowedCountryCodes;
  final bool isPhoneNumberRequired;

  const ShippingAddressParameters({
    this.allowedCountryCodes,
    this.isPhoneNumberRequired = false,
  });

  @override
  String toString() => 'ShippingAddressParameters('
      'allowedCountryCodes: $allowedCountryCodes, '
      'isPhoneNumberRequired: $isPhoneNumberRequired)';
}
