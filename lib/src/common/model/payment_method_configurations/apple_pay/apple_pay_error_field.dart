enum ApplePayErrorField {
  // Contact fields (for .contact errors → PKContactField)
  emailAddress,
  phoneNumber,
  postalAddress,
  name,
  phoneticName,

  // Address fields (for .billingAddress / .shippingAddress errors → CNPostalAddress key)
  street,
  city,
  postalCode,
  administrativeArea,
  country,
  countryCode,
  subLocality,
  subAdministrativeArea,
}
