import 'package:adyen_checkout/adyen_checkout.dart';

extension CardConfigurationExtension on CardConfiguration {
  static CardConfiguration fromJson(Map<String, dynamic> json) {
    return CardConfiguration(
      holderNameRequired: json['holderNameRequired'] ?? false,
      addressMode: _parseAddressMode(json['addressMode']),
      showStorePaymentField: json['showStorePaymentField'] ?? false,
      showCvcForStoredCard: json['showCvcForStoredCard'] ?? true,
      showCvc: json['showCvc'] ?? true,
      kcpFieldVisibility: _parseFieldVisibility(json['kcpFieldVisibility']),
      socialSecurityNumberFieldVisibility:
          _parseFieldVisibility(json['socialSecurityNumberFieldVisibility']),
      supportedCardTypes: (json['supportedCardTypes'] as List<dynamic>?)
              ?.map((element) => element as String)
              .toList() ??
          [],
    );
  }

  CardConfiguration copyWith({
    bool? holderNameRequired,
    AddressMode? addressMode,
    bool? showStorePaymentField,
    bool? showCvcForStoredCard,
    bool? showCvc,
    FieldVisibility? kcpFieldVisibility,
    FieldVisibility? socialSecurityNumberFieldVisibility,
    List<String>? supportedCardTypes,
    Function(List<BinLookupData>)? onBinLookup,
    Function(String)? onBinValue,
  }) {
    return CardConfiguration(
      holderNameRequired: holderNameRequired ?? this.holderNameRequired,
      addressMode: addressMode ?? this.addressMode,
      showStorePaymentField:
          showStorePaymentField ?? this.showStorePaymentField,
      showCvcForStoredCard: showCvcForStoredCard ?? this.showCvcForStoredCard,
      showCvc: showCvc ?? this.showCvc,
      kcpFieldVisibility: kcpFieldVisibility ?? this.kcpFieldVisibility,
      socialSecurityNumberFieldVisibility:
          socialSecurityNumberFieldVisibility ??
              this.socialSecurityNumberFieldVisibility,
      supportedCardTypes: supportedCardTypes ?? this.supportedCardTypes,
      onBinLookup: onBinLookup ?? this.onBinLookup,
      onBinValue: onBinValue ?? this.onBinValue,
    );
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
