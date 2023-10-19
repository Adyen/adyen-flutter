class DeliveryAddress {
  String? city;
  String? country;
  String? houseNumberOrName;
  String? postalCode;
  String? street;
  String? firstName;
  String? lastName;
  String? stateOrProvince;

  DeliveryAddress({
    this.city,
    this.country,
    this.houseNumberOrName,
    this.postalCode,
    this.street,
    this.firstName,
    this.lastName,
    this.stateOrProvince
  });

  DeliveryAddress.fromJson(Map<String, dynamic> json) {
    city = json['city'];
    country = json['country'];
    houseNumberOrName = json['houseNumberOrName'];
    postalCode = json['postalCode'];
    street = json['street'];
    firstName = json['firstname'];
    lastName = json['firstname'];
    stateOrProvince = json['stateOrProvince'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['city'] = city;
    data['country'] = country;
    data['houseNumberOrName'] = houseNumberOrName;
    data['postalCode'] = postalCode;
    data['street'] = street;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['stateOrProvince'] = stateOrProvince;
    return data;
  }
}
