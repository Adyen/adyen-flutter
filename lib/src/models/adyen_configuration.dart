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

//1. Identify common grounds for the four configs on native side
//2. CashPay config,

class DropInConfiguration extends DropInConfigurationDTO
    implements AdyenConfiguration {
  DropInConfiguration({
    required super.environment,
    required super.clientKey,
    required super.countryCode,
    required super.amount,
    String? shopperLocale,
    CardsConfiguration? cardsConfiguration,
    ApplePayConfiguration? applePayConfiguration,
    GooglePayConfiguration? googlePayConfiguration,
    AnalyticsOptions? analyticsOptions,
    bool showPreselectedStoredPaymentMethod = false,
    bool skipListWhenSinglePaymentMethod = false,
  }) : super(
    shopperLocale: shopperLocale,
          cardsConfigurationDTO: _toCardsConfigurationDTO(cardsConfiguration),
          applePayConfigurationDTO:
              _toApplePayConfigurationDTO(applePayConfiguration),
          googlePayConfigurationDTO:
              _toGooglePayConfiguration(googlePayConfiguration),
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
      showCvcForStoredCard: cardsConfiguration.showCvcForStoredCard,
      showCvc: cardsConfiguration.showCvc,
      showKcpField: cardsConfiguration.showKcpField,
      showSocialSecurityNumberField:
          cardsConfiguration.showSocialSecurityNumberField,
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

  static GooglePayConfigurationDTO? _toGooglePayConfiguration(
      GooglePayConfiguration? googlePayConfiguration) {
    if (googlePayConfiguration == null) {
      return null;
    }

    return GooglePayConfigurationDTO(
        merchantAccount: googlePayConfiguration.merchantAccount,
        allowedCardNetworks: googlePayConfiguration.allowedCardNetworks,
        allowedAuthMethods: googlePayConfiguration.allowedAuthMethods
            .map((allowedAuthMethod) => allowedAuthMethod.name)
            .toList(),
        totalPriceStatus: googlePayConfiguration.totalPriceStatus,
        allowPrepaidCards: googlePayConfiguration.allowPrepaidCards,
        billingAddressRequired: googlePayConfiguration.billingAddressRequired,
        emailRequired: googlePayConfiguration.emailRequired,
        shippingAddressRequired: googlePayConfiguration.shippingAddressRequired,
        existingPaymentMethodRequired:
            googlePayConfiguration.existingPaymentMethodRequired,
        googlePayEnvironment: googlePayConfiguration.googlePayEnvironment);
  }
}

class CardsConfiguration extends CardsConfigurationDTO {
  CardsConfiguration({
    bool holderNameRequired = false,
    AddressMode addressMode = AddressMode.none,
    bool showStorePaymentField = false,
    bool showCvcForStoredCard = true,
    bool showCvc = true,
    bool showKcpField = false,
    bool showSocialSecurityNumberField = false,
    List<String?> supportedCardTypes = const [],
  }) : super(
          holderNameRequired: holderNameRequired,
          addressMode: addressMode,
          showStorePaymentField: showStorePaymentField,
          showCvcForStoredCard: showCvcForStoredCard,
          showCvc: showCvc,
          showKcpField: showKcpField,
          showSocialSecurityNumberField: showSocialSecurityNumberField,
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
