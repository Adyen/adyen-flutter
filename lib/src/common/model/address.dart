/// A postal address.
///
/// Field names match the Adyen Checkout API's address schema. [apartment] is
/// an Android-unsupported, iOS-only convenience field that gets folded into
/// [houseNumberOrName] by the native SDK before the payment request is sent.
class Address {
  final String? city;
  final String? country;
  final String? houseNumberOrName;
  final String? postalCode;
  final String? stateOrProvince;
  final String? street;
  final String? apartment;

  const Address({
    this.city,
    this.country,
    this.houseNumberOrName,
    this.postalCode,
    this.stateOrProvince,
    this.street,
    this.apartment,
  });

  @override
  String toString() {
    return 'Address('
        'city: $city, '
        'country: $country, '
        'houseNumberOrName: $houseNumberOrName, '
        'postalCode: $postalCode, '
        'stateOrProvince: $stateOrProvince, '
        'street: $street, '
        'apartment: $apartment)';
  }
}
