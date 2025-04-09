class BillingAddressParameters {
  final String? format;
  final bool? isPhoneNumberRequired;

  BillingAddressParameters({
    this.format,
    this.isPhoneNumberRequired,
  });

  @override
  String toString() {
    return 'BillingAddressParameters('
        'format: $format, '
        'isPhoneNumberRequired: $isPhoneNumberRequired)';
  }
}
