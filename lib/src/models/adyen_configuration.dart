import 'package:adyen_checkout/src/generated/platform_api.g.dart';

abstract class AdyenConfiguration {
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final Amount amount;

  AdyenConfiguration(
    this.environment,
    this.clientKey,
    this.countryCode,
    this.amount,
  );
}

class DropInConfiguration extends DropInConfigurationDTO
    implements AdyenConfiguration {
  DropInConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required super.amount,
    CardsConfiguration? cardsConfiguration,
    AnalyticsOptions? analyticsOptions,
    bool showPreselectedStoredPaymentMethod = false,
    bool skipListWhenSinglePaymentMethod = false,
  }) : super(
          analyticsOptions: analyticsOptions,
          showPreselectedStoredPaymentMethod:
              showPreselectedStoredPaymentMethod,
          skipListWhenSinglePaymentMethod: skipListWhenSinglePaymentMethod,
          cardsConfiguration: CardsConfigurationDTO(
            holderNameRequired: cardsConfiguration?.holderNameRequired ?? false,
            addressMode: cardsConfiguration?.addressMode ?? AddressMode.none,
            showStorePaymentField:
                cardsConfiguration?.showStorePaymentField ?? false,
            hideCvcStoredCard: cardsConfiguration?.hideCvcStoredCard ?? false,
            hideCvc: cardsConfiguration?.hideCvc ?? false,
            kcpVisible: cardsConfiguration?.kcpVisible ?? false,
            socialSecurityVisible:
                cardsConfiguration?.socialSecurityVisible ?? false,
            supportedCardTypes: cardsConfiguration?.supportedCardTypes ?? [],
          ),
        );
}

class CardsConfiguration extends CardsConfigurationDTO {
  CardsConfiguration({
    bool holderNameRequired = false,
    AddressMode addressMode = AddressMode.none,
    bool showStorePaymentField = false,
    bool hideCvcStoredCard = false,
    bool hideCvc = false,
    bool kcpVisible = false,
    bool socialSecurityVisible = false,
    List<String?> supportedCardTypes = const [],
  }) : super(
          holderNameRequired: holderNameRequired,
          addressMode: addressMode,
          showStorePaymentField: showStorePaymentField,
          hideCvcStoredCard: hideCvcStoredCard,
          hideCvc: hideCvc,
          kcpVisible: kcpVisible,
          socialSecurityVisible: socialSecurityVisible,
          supportedCardTypes: supportedCardTypes,
        );
}

class ApplePayConfiguration extends AdyenConfiguration {
  final String merchantId;
  final String merchantName;
  final bool allowOnboarding;

  ApplePayConfiguration(
    super.environment,
    super.clientKey,
    super.countryCode,
    super.amount, {
    required this.merchantId,
    required this.merchantName,
    this.allowOnboarding = false,
  });
}

class GooglePayConfiguration extends AdyenConfiguration {
  final String merchantAccount;
  final List<String> allowedCardNetworks;
  final List<CardAuthMethod> allowedAuthMethods;
  final TotalPriceStatus totalPriceStatus;
  final bool allowPrepaidCards;
  final bool billingAddressRequired;
  final bool emailRequired;
  final bool shippingAddressRequired;
  final bool existingPaymentMethodRequired;
  final GooglePayEnvironment googlePayEnvironment;

  GooglePayConfiguration(
    super.environment,
    super.clientKey,
    super.countryCode,
    super.amount, {
    required this.totalPriceStatus,
    required this.googlePayEnvironment,
    this.merchantAccount = "",
    this.allowedCardNetworks = const [],
    this.allowedAuthMethods = const [],
    this.allowPrepaidCards = true,
    this.billingAddressRequired = false,
    this.emailRequired = false,
    this.shippingAddressRequired = false,
    this.existingPaymentMethodRequired = false,
  });
}

enum CardAuthMethod {
  panOnly,
  cryptogram3DS,
}

enum TotalPriceStatus {
  notCurrentlyKnown,
  estimated,
  finalPrice,
}

enum GooglePayEnvironment {
  test,
  production,
}
