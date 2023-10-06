import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class CardsConfiguration {
  final bool holderNameRequired;
  final AddressMode addressMode;
  final bool showStorePaymentField;
  final bool showCvcForStoredCard;
  final bool showCvc;
  final FieldVisibility kcpFieldVisibility;
  final FieldVisibility socialSecurityNumberFieldVisibility;
  final List<String?> supportedCardTypes;

  CardsConfiguration({
    this.holderNameRequired = false,
    this.addressMode = AddressMode.none,
    this.showStorePaymentField = false,
    this.showCvcForStoredCard = false,
    this.showCvc = true,
    this.kcpFieldVisibility = FieldVisibility.hide,
    this.socialSecurityNumberFieldVisibility = FieldVisibility.hide,
    this.supportedCardTypes = const [],
  });
}
