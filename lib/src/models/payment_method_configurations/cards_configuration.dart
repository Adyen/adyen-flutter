import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class CardsConfiguration extends CardsConfigurationDTO {
  CardsConfiguration({
    bool holderNameRequired = false,
    AddressMode addressMode = AddressMode.none,
    bool showStorePaymentField = false,
    bool showCvcForStoredCard = true,
    bool showCvc = true,
    FieldVisibility kcpFieldVisibility = FieldVisibility.hide,
    FieldVisibility socialSecurityNumberFieldVisibility = FieldVisibility.hide,
    List<String?> supportedCardTypes = const [],
  }) : super(
          holderNameRequired: holderNameRequired,
          addressMode: addressMode,
          showStorePaymentField: showStorePaymentField,
          showCvcForStoredCard: showCvcForStoredCard,
          showCvc: showCvc,
          kcpFieldVisibility: kcpFieldVisibility,
          socialSecurityNumberFieldVisibility:
              socialSecurityNumberFieldVisibility,
          supportedCardTypes: supportedCardTypes,
        );
}
