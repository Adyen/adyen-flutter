import 'package:adyen_checkout/src/generated/platform_api.g.dart';

sealed class AdyenConfiguration {
  final Environment environment;
  final String clientKey;
  final Amount amount;
  final String countryCode;
  final AnalyticsOptions? analytics;

  AdyenConfiguration({
    required this.environment,
    required this.clientKey,
    required this.amount,
    required this.countryCode,
    required this.analytics,
  });
}

class DropInConfiguration extends AdyenConfiguration {
  final bool showPreselectedStoredPaymentMethod;
  final bool skipListWhenSinglePaymentMethod;

  DropInConfiguration({
    required super.environment,
    required super.clientKey,
    required super.amount,
    required super.countryCode,
    super.analytics,
    this.showPreselectedStoredPaymentMethod = false,
    this.skipListWhenSinglePaymentMethod = false,
  });
}

class CardsConfiguration extends AdyenConfiguration {
  final bool holderNameRequired;
  final AddressMode addressVisibility;
  final bool showStorePaymentField;
  final bool hideCvcStoredCard;
  final bool hideCvc;
  final bool kcpVisible;
  final bool socialSecurityVisible;
  final List<String> supportedCardTypes;

  CardsConfiguration({
    required super.environment,
    required super.clientKey,
    required super.amount,
    required super.countryCode,
    super.analytics,
    this.holderNameRequired = false,
    this.addressVisibility = AddressMode.none,
    this.showStorePaymentField = false,
    this.hideCvcStoredCard = false,
    this.hideCvc = false,
    this.kcpVisible = false,
    this.socialSecurityVisible = false,
    this.supportedCardTypes = const [],
  });
}

enum AddressMode {
  full,
  postalCode,
  none,
}

class ApplePayConfiguration extends AdyenConfiguration {
  final String merchantId;
  final String merchantName;
  final bool allowOnboarding;

  ApplePayConfiguration({
    required super.environment,
    required super.clientKey,
    required super.amount,
    required super.countryCode,
    required super.analytics,
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

  GooglePayConfiguration({
    required super.environment,
    required super.clientKey,
    required super.amount,
    required super.countryCode,
    required super.analytics,
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
