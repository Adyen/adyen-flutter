import 'package:pigeon/pigeon.dart';

// dart run pigeon --input pigeons/platform_api.dart
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/platform_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/src/main/kotlin/com/adyen/checkout/flutter/generated/PlatformApi.kt',
  kotlinOptions: KotlinOptions(
    package: 'com.adyen.checkout.flutter.generated',
    errorClassName: 'AdyenPigeonError',
  ),
  swiftOut:
      'ios/adyen_checkout/Sources/adyen_checkout/generated/PlatformApi.swift',
  swiftOptions: SwiftOptions(errorClassName: 'AdyenPigeonError'),
  dartPackageName: 'adyen_checkout',
))
enum EnvironmentDTO {
  test,
  liveEurope,
  liveUnitedStates,
  liveAustralia,
  liveApse,
  liveIndia,
  liveNea,
}

enum BillingAddressModeDTO {
  none,
  postalCode,
}

enum FieldVisibilityDTO {
  show,
  hide,
  auto,
}

enum GooglePayEnvironmentDTO {
  test,
  production,
}

enum TotalPriceStatusDTO {
  notCurrentlyKnown,
  estimated,
  finalPrice,
}

enum ApplePayShippingTypeDTO {
  shipping,
  delivery,
  storePickup,
  servicePickup,
}

enum ApplePayMerchantCapabilityDTO {
  debit,
  credit,
}

enum ApplePaySummaryItemTypeDTO {
  pending,
  definite,
}

enum ApplePayPaymentErrorTypeDTO {
  billingAddress,
  shippingAddress,
  contact,
  couponCode,
  shippingAddressUnserviceable,
  couponCodeExpired,
  unknown,
}

enum ApplePayButtonThemeDTO {
  black,
  white,
  whiteWithLine,
}

enum ApplePayButtonTypeDTO {
  plain,
  buy,
  setUp,
  inStore,
  donate,
  checkout,
  book,
  subscribe,
  reload,
  addMoney,
  topUp,
  order,
  rent,
  support,
  contribute,
  tip,
}

enum CheckoutEventTypeDTO {
  componentReady,
  resize,
  binLookup,
  binValue,
  complete,
  failure,
}

enum SubmitResultTypeDTO {
  completion,
  action,
  retry,
}

class SessionResponseDTO {
  final String id;
  final String sessionData;

  SessionResponseDTO({
    required this.id,
    required this.sessionData,
  });
}

class AmountDTO {
  final String currency;
  final int value;

  AmountDTO({
    required this.currency,
    required this.value,
  });
}

class AnalyticsConfigurationDTO {
  final bool enabled;

  AnalyticsConfigurationDTO({
    required this.enabled,
  });
}

class InstallmentOptionsDTO {
  final List<int> values;
  final bool includesRevolving;
  final String? cardBrand;

  InstallmentOptionsDTO({
    required this.values,
    required this.includesRevolving,
    this.cardBrand,
  });
}

class InstallmentConfigurationDTO {
  final List<InstallmentOptionsDTO> options;
  final bool showInstallmentAmount;

  InstallmentConfigurationDTO({
    required this.options,
    required this.showInstallmentAmount,
  });
}

class CardConfigurationDTO {
  final BillingAddressModeDTO billingAddressMode;
  final FieldVisibilityDTO koreanAuthenticationVisibility;
  final bool showCardholderName;
  final bool showSecurityCode;
  final bool showSecurityCodeForStoredCard;
  final bool showStorePaymentMethod;
  final bool showSupportedCardBrandLogos;
  final FieldVisibilityDTO socialSecurityNumberVisibility;
  final List<String>? supportedCardBrands;
  final InstallmentConfigurationDTO? installmentConfiguration;
  final bool hasOnBinChange;
  final bool hasOnBinLookup;

  CardConfigurationDTO({
    required this.billingAddressMode,
    required this.koreanAuthenticationVisibility,
    required this.showCardholderName,
    required this.showSecurityCode,
    required this.showSecurityCodeForStoredCard,
    required this.showStorePaymentMethod,
    required this.showSupportedCardBrandLogos,
    required this.socialSecurityNumberVisibility,
    this.supportedCardBrands,
    this.installmentConfiguration,
    required this.hasOnBinChange,
    required this.hasOnBinLookup,
  });
}

class MerchantInfoDTO {
  final String? merchantName;
  final String? merchantId;

  MerchantInfoDTO({
    this.merchantName,
    this.merchantId,
  });
}

class ShippingAddressParametersDTO {
  final List<String>? allowedCountryCodes;
  final bool isPhoneNumberRequired;

  ShippingAddressParametersDTO({
    this.allowedCountryCodes,
    required this.isPhoneNumberRequired,
  });
}

class GooglePayConfigurationDTO {
  final GooglePayEnvironmentDTO googlePayEnvironment;
  final String? merchantAccount;
  final MerchantInfoDTO? merchantInfo;
  final TotalPriceStatusDTO? totalPriceStatus;
  final bool? emailRequired;
  final bool? existingPaymentMethodRequired;
  final bool? shippingAddressRequired;
  final ShippingAddressParametersDTO? shippingAddressParameters;

  GooglePayConfigurationDTO({
    required this.googlePayEnvironment,
    this.merchantAccount,
    this.merchantInfo,
    this.totalPriceStatus,
    this.emailRequired,
    this.existingPaymentMethodRequired,
    this.shippingAddressRequired,
    this.shippingAddressParameters,
  });
}

class ApplePayContactDTO {
  final String? phoneNumber;
  final String? emailAddress;
  final String? givenName;
  final String? familyName;
  final String? phoneticGivenName;
  final String? phoneticFamilyName;
  final List<String>? addressLines;
  final String? subLocality;
  final String? city;
  final String? postalCode;
  final String? subAdministrativeArea;
  final String? administrativeArea;
  final String? country;
  final String? countryCode;

  ApplePayContactDTO({
    this.phoneNumber,
    this.emailAddress,
    this.givenName,
    this.familyName,
    this.phoneticGivenName,
    this.phoneticFamilyName,
    this.addressLines,
    this.subLocality,
    this.city,
    this.postalCode,
    this.subAdministrativeArea,
    this.administrativeArea,
    this.country,
    this.countryCode,
  });
}

class ApplePaySummaryItemDTO {
  final String label;
  final AmountDTO amount;
  final ApplePaySummaryItemTypeDTO type;

  ApplePaySummaryItemDTO({
    required this.label,
    required this.amount,
    required this.type,
  });
}

class ApplePayShippingMethodDTO {
  final String label;
  final String detail;
  final AmountDTO amount;
  final String identifier;
  final String? startDate;
  final String? endDate;

  ApplePayShippingMethodDTO({
    required this.label,
    required this.detail,
    required this.amount,
    required this.identifier,
    this.startDate,
    this.endDate,
  });
}

class ApplePayPaymentErrorDTO {
  final ApplePayPaymentErrorTypeDTO type;
  final String? field;
  final String localizedDescription;

  ApplePayPaymentErrorDTO({
    required this.type,
    this.field,
    required this.localizedDescription,
  });
}

class ApplePayAuthorizedPaymentDTO {
  final String token;
  final String network;
  final ApplePayContactDTO? billingContact;
  final ApplePayContactDTO? shippingContact;
  final ApplePayShippingMethodDTO? shippingMethod;

  ApplePayAuthorizedPaymentDTO({
    required this.token,
    required this.network,
    this.billingContact,
    this.shippingContact,
    this.shippingMethod,
  });
}

class ApplePayAuthorizationResultDTO {
  final bool isSuccess;
  final List<ApplePayPaymentErrorDTO>? errors;

  ApplePayAuthorizationResultDTO({
    required this.isSuccess,
    this.errors,
  });
}

class ApplePayShippingMethodUpdateDTO {
  final List<ApplePaySummaryItemDTO> summaryItems;

  ApplePayShippingMethodUpdateDTO({
    required this.summaryItems,
  });
}

class ApplePayShippingContactUpdateDTO {
  final List<ApplePaySummaryItemDTO> summaryItems;
  final List<ApplePayShippingMethodDTO>? shippingMethods;
  final List<ApplePayPaymentErrorDTO>? errors;

  ApplePayShippingContactUpdateDTO({
    required this.summaryItems,
    this.shippingMethods,
    this.errors,
  });
}

class ApplePayCouponCodeUpdateDTO {
  final List<ApplePaySummaryItemDTO> summaryItems;
  final List<ApplePayShippingMethodDTO>? shippingMethods;
  final List<ApplePayPaymentErrorDTO>? errors;

  ApplePayCouponCodeUpdateDTO({
    required this.summaryItems,
    this.shippingMethods,
    this.errors,
  });
}

class ApplePayButtonStyleDTO {
  final ApplePayButtonThemeDTO? theme;
  final ApplePayButtonTypeDTO? type;
  final double? cornerRadius;

  ApplePayButtonStyleDTO({
    this.theme,
    this.type,
    this.cornerRadius,
  });
}

class ApplePayConfigurationDTO {
  final String merchantId;
  final String merchantName;
  final bool? allowOnboarding;
  final List<ApplePaySummaryItemDTO>? summaryItems;
  final List<String>? requiredBillingContactFields;
  final ApplePayContactDTO? billingContact;
  final List<String>? requiredShippingContactFields;
  final ApplePayContactDTO? shippingContact;
  final ApplePayShippingTypeDTO? shippingType;
  final bool? allowShippingContactEditing;
  final List<ApplePayShippingMethodDTO>? shippingMethods;
  final String? applicationData;
  final List<String>? supportedCountries;
  final ApplePayMerchantCapabilityDTO? merchantCapability;
  final bool? supportsCouponCode;
  final String? couponCode;
  final ApplePayButtonStyleDTO? buttonStyle;
  final double? buttonWidth;
  final double? buttonHeight;
  final bool hasOnSelectShippingMethod;
  final bool hasOnSelectShippingContact;
  final bool hasOnChangeCouponCode;
  final bool hasOnAuthorize;

  ApplePayConfigurationDTO({
    required this.merchantId,
    required this.merchantName,
    this.allowOnboarding,
    this.summaryItems,
    this.requiredBillingContactFields,
    this.billingContact,
    this.requiredShippingContactFields,
    this.shippingContact,
    this.shippingType,
    this.allowShippingContactEditing,
    this.shippingMethods,
    this.applicationData,
    this.supportedCountries,
    this.merchantCapability,
    this.supportsCouponCode,
    this.couponCode,
    this.buttonStyle,
    this.buttonWidth,
    this.buttonHeight,
    required this.hasOnSelectShippingMethod,
    required this.hasOnSelectShippingContact,
    required this.hasOnChangeCouponCode,
    required this.hasOnAuthorize,
  });
}

class CheckoutConfigurationDTO {
  final EnvironmentDTO environment;
  final String clientKey;
  final String? countryCode;
  final AmountDTO? amount;
  final AnalyticsConfigurationDTO analyticsConfiguration;
  final bool showSubmitButton;
  final CardConfigurationDTO? cardConfiguration;
  final ApplePayConfigurationDTO? applePayConfiguration;
  final GooglePayConfigurationDTO? googlePayConfiguration;

  CheckoutConfigurationDTO({
    required this.environment,
    required this.clientKey,
    this.countryCode,
    this.amount,
    required this.analyticsConfiguration,
    required this.showSubmitButton,
    this.cardConfiguration,
    this.applePayConfiguration,
    this.googlePayConfiguration,
  });
}

class CheckoutSetupResultDTO {
  final String checkoutId;
  final String regularPaymentMethodsJson;
  final String storedPaymentMethodsJson;

  CheckoutSetupResultDTO({
    required this.checkoutId,
    required this.regularPaymentMethodsJson,
    required this.storedPaymentMethodsJson,
  });
}

class BeforeSubmitDataDTO {
  final AddressDTO? billingAddress;
  final AddressDTO? deliveryAddress;
  final ShopperNameDTO? shopperName;
  final String? shopperEmail;

  BeforeSubmitDataDTO({
    this.billingAddress,
    this.deliveryAddress,
    this.shopperName,
    this.shopperEmail,
  });
}

class BeforeSubmitResultDTO {
  final bool isAborted;
  final BeforeSubmitDataDTO? data;
  final String? sessionData;

  BeforeSubmitResultDTO({
    required this.isAborted,
    this.data,
    this.sessionData,
  });
}

class AddressDTO {
  final String? city;
  final String? country;
  final String? houseNumberOrName;
  final String? postalCode;
  final String? stateOrProvince;
  final String? street;

  AddressDTO({
    this.city,
    this.country,
    this.houseNumberOrName,
    this.postalCode,
    this.stateOrProvince,
    this.street,
  });
}

class ShopperNameDTO {
  final String? firstName;
  final String? lastName;
  final String? infix;
  final String? gender;

  ShopperNameDTO({
    this.firstName,
    this.lastName,
    this.infix,
    this.gender,
  });
}

class PaymentComponentDataDTO {
  final String dataJson;

  PaymentComponentDataDTO({
    required this.dataJson,
  });
}

class ActionComponentDataDTO {
  final String dataJson;

  ActionComponentDataDTO({
    required this.dataJson,
  });
}

class SubmitResultDTO {
  final SubmitResultTypeDTO type;
  final String? resultCode;
  final String? actionJson;
  final String? errorMessage;

  SubmitResultDTO({
    required this.type,
    this.resultCode,
    this.actionJson,
    this.errorMessage,
  });
}

class AdditionalDetailsResultDTO {
  final String resultCode;

  AdditionalDetailsResultDTO({
    required this.resultCode,
  });
}

class AdvancedCheckoutResultDTO {
  final String resultCode;

  AdvancedCheckoutResultDTO({
    required this.resultCode,
  });
}

class UnencryptedCardDTO {
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvc;

  UnencryptedCardDTO({
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvc,
  });
}

class EncryptedCardDTO {
  final String? encryptedCardNumber;
  final String? encryptedExpiryMonth;
  final String? encryptedExpiryYear;
  final String? encryptedSecurityCode;

  EncryptedCardDTO({
    this.encryptedCardNumber,
    this.encryptedExpiryMonth,
    this.encryptedExpiryYear,
    this.encryptedSecurityCode,
  });
}

class BinLookupBrandDTO {
  final String brand;
  final bool supported;
  final String? paymentMethodVariant;

  BinLookupBrandDTO({
    required this.brand,
    required this.supported,
    this.paymentMethodVariant,
  });
}

class BinLookupDataDTO {
  final String? issuingCountryCode;
  final List<BinLookupBrandDTO> brands;

  BinLookupDataDTO({
    this.issuingCountryCode,
    required this.brands,
  });
}

class CheckoutEventDTO {
  final CheckoutEventTypeDTO type;
  final String checkoutId;
  final String? componentId;
  final bool? requiresUserInteraction;
  final int? height;
  final List<BinLookupDataDTO>? binLookupData;
  final String? binValue;
  final String? resultCode;
  final String? sessionId;
  final String? sessionResult;
  final String? errorCode;
  final String? errorMessage;

  CheckoutEventDTO({
    required this.type,
    required this.checkoutId,
    this.componentId,
    this.requiresUserInteraction,
    this.height,
    this.binLookupData,
    this.binValue,
    this.resultCode,
    this.sessionId,
    this.sessionResult,
    this.errorCode,
    this.errorMessage,
  });
}

@HostApi()
abstract class CheckoutHostApi {
  @async
  CheckoutSetupResultDTO setupSession(
    SessionResponseDTO sessionResponse,
    CheckoutConfigurationDTO configuration,
  );

  @async
  CheckoutSetupResultDTO setupAdvanced(
    String paymentMethodsJson,
    CheckoutConfigurationDTO configuration,
  );

  void disposeCheckout(String checkoutId);

  @async
  AdvancedCheckoutResultDTO handleAction(
    String actionId,
    String actionJson,
    CheckoutConfigurationDTO configuration,
  );

  void enableConsoleLogging(bool enabled);

  @async
  EncryptedCardDTO encryptCard(
    UnencryptedCardDTO card,
    String publicKey,
  );

  @async
  String encryptBin(String bin, String publicKey);

  bool validateCardNumber(String cardNumber, bool enableLuhnCheck);

  bool validateCardExpiryDate(String expiryMonth, String expiryYear);

  bool validateCardSecurityCode(String securityCode, String? cardBrand);

  String getThreeDS2SdkVersion();
}

@HostApi()
abstract class ComponentHostApi {
  @async
  void submit(String checkoutId, String componentId);

  void dispose(String checkoutId, String componentId);
}

@FlutterApi()
abstract class CheckoutCallbacksFlutterApi {
  @async
  BeforeSubmitResultDTO onBeforeSubmit(
    String checkoutId,
    BeforeSubmitDataDTO data,
  );

  @async
  SubmitResultDTO onSubmit(
    String checkoutId,
    PaymentComponentDataDTO data,
  );

  @async
  AdditionalDetailsResultDTO onAdditionalDetails(
    String checkoutId,
    ActionComponentDataDTO data,
  );

  @async
  ApplePayShippingMethodUpdateDTO onApplePaySelectShippingMethod(
    String checkoutId,
    ApplePayShippingMethodDTO shippingMethod,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  );

  @async
  ApplePayShippingContactUpdateDTO onApplePaySelectShippingContact(
    String checkoutId,
    ApplePayContactDTO contact,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  );

  @async
  ApplePayCouponCodeUpdateDTO onApplePayChangeCouponCode(
    String checkoutId,
    String couponCode,
    List<ApplePaySummaryItemDTO> currentSummaryItems,
  );

  @async
  ApplePayAuthorizationResultDTO onApplePayAuthorize(
    String checkoutId,
    ApplePayAuthorizedPaymentDTO payment,
  );
}

@FlutterApi()
abstract class ActionOnlyFlutterApi {
  @async
  AdditionalDetailsResultDTO onAdditionalDetails(
    String actionId,
    ActionComponentDataDTO data,
  );
}

@EventChannelApi()
abstract class CheckoutEvents {
  CheckoutEventDTO events();
}
