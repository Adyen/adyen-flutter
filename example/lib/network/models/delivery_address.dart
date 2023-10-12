class DeliveryAddress {
  String? city;
  String? country;
  String? houseNumberOrName;
  String? postalCode;
  String? street;

  DeliveryAddress({
    this.city,
    this.country,
    this.houseNumberOrName,
    this.postalCode,
    this.street,
  });

  DeliveryAddress.fromJson(Map<String, dynamic> json) {
    city = json['city'];
    country = json['country'];
    houseNumberOrName = json['houseNumberOrName'];
    postalCode = json['postalCode'];
    street = json['street'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['city'] = city;
    data['country'] = country;
    data['houseNumberOrName'] = houseNumberOrName;
    data['postalCode'] = postalCode;
    data['street'] = street;
    return data;
  }
}
