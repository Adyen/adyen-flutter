class ShippingAddressParameters {
  final List<String>? allowedCountryCodes;
  final bool? isPhoneNumberRequired;

  ShippingAddressParameters({
    this.allowedCountryCodes,
    this.isPhoneNumberRequired,
  });

  @override
  String toString() {
    return 'ShippingAddressParameters('
        'allowedCountryCodes: $allowedCountryCodes, '
        'isPhoneNumberRequired: $isPhoneNumberRequired)';
  }
}
