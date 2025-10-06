import 'package:adyen_checkout/adyen_checkout.dart';

extension CardConfigurationExtension on CardConfiguration {
  static CardConfiguration fromJson(Map<String, dynamic> json) {
    return CardConfiguration(
        holderNameRequired: json['holderNameRequired'] ?? false,
        addressMode: _parseAddressMode(json['addressMode']),
        showStorePaymentField: json['showStorePaymentField'] ?? true,
        showCvcForStoredCard: json['showCvcForStoredCard'] ?? true,
        showCvc: json['showCvc'] ?? true,
        kcpFieldVisibility: _parseFieldVisibility(json['kcpFieldVisibility']),
        socialSecurityNumberFieldVisibility:
        _parseFieldVisibility(json['socialSecurityNumberFieldVisibility']),
        supportedCardTypes: (json['supportedCardTypes'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
            [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'holderNameRequired': holderNameRequired,
      'addressMode': addressMode.name,
      'showStorePaymentField': showStorePaymentField,
      'showCvcForStoredCard': showCvcForStoredCard,
      'showCvc': showCvc,
      'kcpFieldVisibility': kcpFieldVisibility.name,
      'socialSecurityNumberFieldVisibility':
      socialSecurityNumberFieldVisibility.name,
      'supportedCardTypes': supportedCardTypes,
    };
  }

  static AddressMode _parseAddressMode(String? value) {
    switch (value) {
      case 'full':
        return AddressMode.full;
      case 'postalCode':
        return AddressMode.postalCode;
      case 'none':
      default:
        return AddressMode.none;
    }
  }

  static FieldVisibility _parseFieldVisibility(String? value) {
    switch (value) {
      case 'show':
        return FieldVisibility.show;
      case 'hide':
      default:
        return FieldVisibility.hide;
    }
  }
}
