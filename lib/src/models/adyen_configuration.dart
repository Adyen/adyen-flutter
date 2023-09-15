import 'package:adyen_checkout/src/generated/platform_api.g.dart';

sealed class AdyenConfiguration {
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
    ApplePayConfiguration? applePayConfiguration,
    AnalyticsOptions? analyticsOptions,
    bool showPreselectedStoredPaymentMethod = false,
    bool skipListWhenSinglePaymentMethod = false,
  }) : super(
          cardsConfigurationDTO: _toCardsConfigurationDTO(cardsConfiguration),
          applePayConfigurationDTO:
              _toApplePayConfigurationDTO(applePayConfiguration),
          analyticsOptionsDTO: _toAnalyticsOptionsDTO(analyticsOptions),
          showPreselectedStoredPaymentMethod:
              showPreselectedStoredPaymentMethod,
          skipListWhenSinglePaymentMethod: skipListWhenSinglePaymentMethod,
        );

  static CardsConfigurationDTO? _toCardsConfigurationDTO(
      CardsConfiguration? cardsConfiguration) {
    if (cardsConfiguration == null) {
      return null;
    }

    return CardsConfigurationDTO(
      holderNameRequired: cardsConfiguration.holderNameRequired,
      addressMode: cardsConfiguration.addressMode,
      showStorePaymentField: cardsConfiguration.showStorePaymentField,
      hideCvcStoredCard: cardsConfiguration.hideCvcStoredCard,
      hideCvc: cardsConfiguration.hideCvc,
      kcpVisible: cardsConfiguration.kcpVisible,
      socialSecurityVisible: cardsConfiguration.socialSecurityVisible,
      supportedCardTypes: cardsConfiguration.supportedCardTypes,
    );
  }

  static ApplePayConfigurationDTO? _toApplePayConfigurationDTO(
      ApplePayConfiguration? applePayConfiguration) {
    if (applePayConfiguration == null) {
      return null;
    }

    return ApplePayConfigurationDTO(
      merchantId: applePayConfiguration.merchantId,
      merchantName: applePayConfiguration.merchantName,
      allowOnboarding: applePayConfiguration.allowOnboarding,
    );
  }

  static AnalyticsOptionsDTO? _toAnalyticsOptionsDTO(
      AnalyticsOptions? analyticsOptions) {
    if (analyticsOptions == null) {
      return null;
    }

    return AnalyticsOptionsDTO(
      enabled: analyticsOptions.enabled,
      payload: analyticsOptions.payload,
    );
  }
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

class AnalyticsOptions {
  final bool? enabled;
  final String? payload;

  AnalyticsOptions({
    this.enabled,
    this.payload,
  });
}

class ApplePayConfiguration {
  final String merchantId;
  final String merchantName;
  final bool allowOnboarding;

  ApplePayConfiguration({
    required this.merchantId,
    required this.merchantName,
    this.allowOnboarding = false,
  });
}

class GooglePayConfiguration {
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

  GooglePayConfiguration({
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
