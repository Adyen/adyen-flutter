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
  final CardCallbacksInterface? cardCallbacks;

  const CardConfiguration({
    this.holderNameRequired = false,
    this.addressMode = AddressMode.none,
    this.showStorePaymentField = false,
    this.showCvcForStoredCard = true,
    this.showCvc = true,
    this.kcpFieldVisibility = FieldVisibility.hide,
    this.socialSecurityNumberFieldVisibility = FieldVisibility.hide,
    this.supportedCardTypes = const [],
    this.cardCallbacks,
  });
}
