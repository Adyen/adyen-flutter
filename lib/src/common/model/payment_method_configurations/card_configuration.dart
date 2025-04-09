import 'package:adyen_checkout/adyen_checkout.dart';

class CardConfiguration {
  final bool holderNameRequired;
  final AddressMode addressMode;
  final bool showStorePaymentField;
  final bool showCvcForStoredCard;
  final bool showCvc;
  final FieldVisibility kcpFieldVisibility;
  final FieldVisibility socialSecurityNumberFieldVisibility;
  final List<String?> supportedCardTypes;
  final void Function(List<BinLookupData>)? onBinLookup;
  final void Function(String)? onBinValue;

  const CardConfiguration({
    this.holderNameRequired = false,
    this.addressMode = AddressMode.none,
    this.showStorePaymentField = false,
    this.showCvcForStoredCard = true,
    this.showCvc = true,
    this.kcpFieldVisibility = FieldVisibility.hide,
    this.socialSecurityNumberFieldVisibility = FieldVisibility.hide,
    this.supportedCardTypes = const [],
    this.onBinLookup,
    this.onBinValue,
  });

  @override
  String toString() {
    return 'CardConfiguration('
        'holderNameRequired: $holderNameRequired, '
        'addressMode: $addressMode, '
        'showStorePaymentField: $showStorePaymentField, '
        'showCvcForStoredCard: $showCvcForStoredCard, '
        'showCvc: $showCvc, '
        'kcpFieldVisibility: $kcpFieldVisibility, '
        'socialSecurityNumberFieldVisibility: $socialSecurityNumberFieldVisibility, '
        'supportedCardTypes: $supportedCardTypes, '
        'onBinLookup: $onBinLookup, '
        'onBinValue: $onBinValue)';
  }
}
