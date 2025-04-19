class ApplePayContact {
  final String? phoneNumber;
  final String? emailAddress;
  final String? givenName;
  final String? familyName;
  final String? phoneticGivenName;
  final String? phoneticFamilyName;
  final List<String>? addressLines;
  final String? subLocality;
  final String? city;
  final String? postalCode;
  final String? subAdministrativeArea;
  final String? administrativeArea;
  final String? country;
  final String? countryCode;

  ApplePayContact({
    this.phoneNumber,
    this.emailAddress,
    this.givenName,
    this.familyName,
    this.phoneticGivenName,
    this.phoneticFamilyName,
    this.addressLines,
    this.subLocality,
    this.city,
    this.postalCode,
    this.subAdministrativeArea,
    this.administrativeArea,
    this.country,
    this.countryCode,
  });

  @override
  String toString() {
    return 'ApplePayContact('
        'phoneNumber: $phoneNumber, '
        'emailAddress: $emailAddress, '
        'givenName: $givenName, '
        'familyName: $familyName, '
        'phoneticGivenName: $phoneticGivenName, '
        'phoneticFamilyName: $phoneticFamilyName, '
        'addressLines: $addressLines, '
        'subLocality: $subLocality, '
        'city: $city, '
        'postalCode: $postalCode, '
        'subAdministrativeArea: $subAdministrativeArea, '
        'administrativeArea: $administrativeArea, '
        'country: $country, '
        'countryCode: $countryCode)';
  }
}
