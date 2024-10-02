import 'package:pigeon/pigeon.dart';

//dart run pigeon --input pigeons/platform_api.dart
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/platform_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/src/main/kotlin/com/adyen/checkout/flutter/PlatformApi.kt',
  kotlinOptions: KotlinOptions(errorClassName: "AdyenPigeonError"),
  swiftOut: 'ios/Classes/PlatformApi.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'adyen_checkout',
))
enum Environment {
  test,
  europe,
  unitedStates,
  australia,
  india,
  apse;
}

enum AddressMode {
  full,
  postalCode,
  none,
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

enum CashAppPayEnvironment {
  sandbox,
  production,
}

enum PaymentResultEnum {
  cancelledByUser,
  error,
  finished,
}

enum PlatformCommunicationType {
  paymentComponent,
  additionalDetails,
  result,
  deleteStoredPaymentMethod,
}

enum ComponentCommunicationType {
  onSubmit,
  additionalDetails,
  loading,
  result,
  resize,
}

enum PaymentEventType {
  finished,
  action,
  error,
}

enum FieldVisibility {
  show,
  hide,
}

enum InstantPaymentType {
  googlePay,
  applePay,
  instant,
}

enum ApplePayShippingType {
  shipping,
  delivery,
  storePickup,
  servicePickup,
}

enum ApplePayMerchantCapability {
  debit,
  credit,
}

enum ApplePaySummaryItemType {
  pending,
  definite,
}

class SessionDTO {
  final String id;
  final String sessionData;
  final String paymentMethodsJson;

  SessionDTO(
    this.id,
    this.sessionData,
    this.paymentMethodsJson,
  );
}

class AmountDTO {
  final String currency;
  final int value;

  AmountDTO(
    this.currency,
    this.value,
  );
}

class AnalyticsOptionsDTO {
  final bool enabled;
  final String version;

  AnalyticsOptionsDTO(
    this.enabled,
    this.version,
  );
}

class DropInConfigurationDTO {
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final AmountDTO? amount;
  final String? shopperLocale;
  final CardConfigurationDTO? cardConfigurationDTO;
  final ApplePayConfigurationDTO? applePayConfigurationDTO;
  final GooglePayConfigurationDTO? googlePayConfigurationDTO;
  final CashAppPayConfigurationDTO? cashAppPayConfigurationDTO;
  final AnalyticsOptionsDTO analyticsOptionsDTO;
  final bool showPreselectedStoredPaymentMethod;
  final bool skipListWhenSinglePaymentMethod;
  final bool isRemoveStoredPaymentMethodEnabled;
  final String? preselectedPaymentMethodTitle;
  final Map<String?, String?>? paymentMethodNames;

  DropInConfigurationDTO(
    this.environment,
    this.clientKey,
    this.countryCode,
    this.amount,
    this.shopperLocale,
    this.cardConfigurationDTO,
    this.applePayConfigurationDTO,
    this.googlePayConfigurationDTO,
    this.cashAppPayConfigurationDTO,
    this.analyticsOptionsDTO,
    this.showPreselectedStoredPaymentMethod,
    this.skipListWhenSinglePaymentMethod,
    this.isRemoveStoredPaymentMethodEnabled,
    this.preselectedPaymentMethodTitle,
    this.paymentMethodNames,
  );
}

class CardConfigurationDTO {
  final bool holderNameRequired;
  final AddressMode addressMode;
  final bool showStorePaymentField;
  final bool showCvcForStoredCard;
  final bool showCvc;
  final FieldVisibility kcpFieldVisibility;
  final FieldVisibility socialSecurityNumberFieldVisibility;
  final List<String?> supportedCardTypes;

  CardConfigurationDTO(
    this.holderNameRequired,
    this.addressMode,
    this.showStorePaymentField,
    this.showCvcForStoredCard,
    this.showCvc,
    this.kcpFieldVisibility,
    this.socialSecurityNumberFieldVisibility,
    this.supportedCardTypes,
  );
}

class ApplePayConfigurationDTO {
  final String merchantId;
  final String merchantName;
  final bool? allowOnboarding;
  final List<ApplePaySummaryItemDTO?>? summaryItems;
  final List<String?>? requiredBillingContactFields;
  final ApplePayContactDTO? billingContact;
  final List<String?>? requiredShippingContactFields;
  final ApplePayContactDTO? shippingContact;
  final ApplePayShippingType? applePayShippingType;
  final bool? allowShippingContactEditing;
  final List<ApplePayShippingMethodDTO?>? shippingMethods;
  final String? applicationData;
  final List<String?>? supportedCountries;
  final ApplePayMerchantCapability? merchantCapability;

  ApplePayConfigurationDTO(
    this.merchantId,
    this.merchantName,
    this.allowOnboarding,
    this.summaryItems,
    this.requiredBillingContactFields,
    this.billingContact,
    this.requiredShippingContactFields,
    this.shippingContact,
    this.applePayShippingType,
    this.allowShippingContactEditing,
    this.shippingMethods,
    this.applicationData,
    this.supportedCountries,
    this.merchantCapability,
  );
}

class ApplePayContactDTO {
  final String? phoneNumber;
  final String? emailAddress;
  final String? givenName;
  final String? familyName;
  final String? phoneticGivenName;
  final String? phoneticFamilyName;
  final List<String?>? addressLines;
  final String? subLocality;
  final String? city;
  final String? postalCode;
  final String? subAdministrativeArea;
  final String? administrativeArea;
  final String? country;
  final String? countryCode;

  ApplePayContactDTO(
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
  );
}

class ApplePayShippingMethodDTO {
  final String label;
  final String detail;
  final AmountDTO amount;
  final String identifier;
  final String? startDate;
  final String? endDate;

  ApplePayShippingMethodDTO(
    this.label,
    this.detail,
    this.amount,
    this.identifier,
    this.startDate,
    this.endDate,
  );
}

class ApplePaySummaryItemDTO {
  final String label;
  final AmountDTO amount;
  final ApplePaySummaryItemType type;

  ApplePaySummaryItemDTO(
    this.label,
    this.amount,
    this.type,
  );
}

class GooglePayConfigurationDTO {
  final GooglePayEnvironment googlePayEnvironment;
  final String? merchantAccount;
  final MerchantInfoDTO? merchantInfoDTO;
  final TotalPriceStatus? totalPriceStatus;
  final List<String?>? allowedCardNetworks;
  final List<String?>? allowedAuthMethods;
  final bool? allowPrepaidCards;
  final bool? allowCreditCards;
  final bool? assuranceDetailsRequired;
  final bool? emailRequired;
  final bool? existingPaymentMethodRequired;
  final bool? shippingAddressRequired;
  final ShippingAddressParametersDTO? shippingAddressParametersDTO;
  final bool? billingAddressRequired;
  final BillingAddressParametersDTO? billingAddressParametersDTO;

  GooglePayConfigurationDTO(
    this.googlePayEnvironment,
    this.merchantAccount,
    this.merchantInfoDTO,
    this.totalPriceStatus,
    this.allowedCardNetworks,
    this.allowedAuthMethods,
    this.allowPrepaidCards,
    this.allowCreditCards,
    this.assuranceDetailsRequired,
    this.emailRequired,
    this.existingPaymentMethodRequired,
    this.shippingAddressRequired,
    this.shippingAddressParametersDTO,
    this.billingAddressRequired,
    this.billingAddressParametersDTO,
  );
}

class MerchantInfoDTO {
  final String? merchantName;
  final String? merchantId;

  MerchantInfoDTO(
    this.merchantName,
    this.merchantId,
  );
}

class ShippingAddressParametersDTO {
  final List<String?>? allowedCountryCodes;
  final bool? isPhoneNumberRequired;

  ShippingAddressParametersDTO(
    this.allowedCountryCodes,
    this.isPhoneNumberRequired,
  );
}

class BillingAddressParametersDTO {
  final String? format;
  final bool? isPhoneNumberRequired;

  BillingAddressParametersDTO(
    this.format,
    this.isPhoneNumberRequired,
  );
}

class CashAppPayConfigurationDTO {
  final CashAppPayEnvironment cashAppPayEnvironment;
  final String returnUrl;

  CashAppPayConfigurationDTO(
    this.cashAppPayEnvironment,
    this.returnUrl,
  );
}

class PaymentResultDTO {
  final PaymentResultEnum type;
  final String? reason;
  final PaymentResultModelDTO? result;

  PaymentResultDTO(
    this.type,
    this.reason,
    this.result,
  );
}

class PaymentResultModelDTO {
  final String? sessionId;
  final String? sessionData;
  final String? sessionResult;
  final String? resultCode;
  final OrderResponseDTO? order;

  PaymentResultModelDTO(
    this.sessionId,
    this.sessionData,
    this.sessionResult,
    this.resultCode,
    this.order,
  );
}

class OrderResponseDTO {
  final String pspReference;
  final String orderData;
  final AmountDTO? amount;
  final AmountDTO? remainingAmount;

  OrderResponseDTO({
    required this.pspReference,
    required this.orderData,
    this.amount,
    this.remainingAmount,
  });
}

class PlatformCommunicationModel {
  final PlatformCommunicationType type;
  final String? data;
  final PaymentResultDTO? paymentResult;

  PlatformCommunicationModel({
    required this.type,
    this.data,
    this.paymentResult,
  });
}

class ComponentCommunicationModel {
  final ComponentCommunicationType type;
  final String componentId;
  final Object? data;
  final PaymentResultDTO? paymentResult;

  ComponentCommunicationModel({
    required this.type,
    required this.componentId,
    this.data,
    this.paymentResult,
  });
}

class PaymentEventDTO {
  final PaymentEventType paymentEventType;
  final String? result;
  final Map<String?, Object?>? actionResponse;
  final ErrorDTO? error;

  PaymentEventDTO({
    required this.paymentEventType,
    this.result,
    this.actionResponse,
    this.error,
  });
}

class ErrorDTO {
  final String? errorMessage;
  final String? reason;
  final bool? dismissDropIn;

  ErrorDTO({
    this.errorMessage,
    this.reason,
    this.dismissDropIn = false,
  });
}

class DeletedStoredPaymentMethodResultDTO {
  final String storedPaymentMethodId;
  final bool isSuccessfullyRemoved;

  DeletedStoredPaymentMethodResultDTO(
    this.storedPaymentMethodId,
    this.isSuccessfullyRemoved,
  );
}

class CardComponentConfigurationDTO {
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final AmountDTO? amount;
  final String? shopperLocale;
  final CardConfigurationDTO cardConfiguration;
  final AnalyticsOptionsDTO analyticsOptionsDTO;

  CardComponentConfigurationDTO(
    this.environment,
    this.clientKey,
    this.countryCode,
    this.amount,
    this.shopperLocale,
    this.cardConfiguration,
    this.analyticsOptionsDTO,
  );
}

class InstantPaymentConfigurationDTO {
  final InstantPaymentType instantPaymentType;
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final AmountDTO? amount;
  final String? shopperLocale;
  final AnalyticsOptionsDTO analyticsOptionsDTO;
  final GooglePayConfigurationDTO? googlePayConfigurationDTO;
  final ApplePayConfigurationDTO? applePayConfigurationDTO;

  InstantPaymentConfigurationDTO(
    this.instantPaymentType,
    this.environment,
    this.clientKey,
    this.countryCode,
    this.amount,
    this.shopperLocale,
    this.analyticsOptionsDTO,
    this.googlePayConfigurationDTO,
    this.applePayConfigurationDTO,
  );
}

class InstantPaymentSetupResultDTO {
  final InstantPaymentType instantPaymentType;
  final bool isSupported;
  final Object? resultData;

  InstantPaymentSetupResultDTO(
    this.instantPaymentType,
    this.isSupported,
    this.resultData,
  );
}

class UnencryptedCardDTO {
  final String? cardNumber;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvc;

  UnencryptedCardDTO(
    this.cardNumber,
    this.expiryMonth,
    this.expiryYear,
    this.cvc,
  );
}

class EncryptedCardDTO {
  final String? encryptedCardNumber;
  final String? encryptedExpiryMonth;
  final String? encryptedExpiryYear;
  final String? encryptedSecurityCode;

  EncryptedCardDTO(
    this.encryptedCardNumber,
    this.encryptedExpiryMonth,
    this.encryptedExpiryYear,
    this.encryptedSecurityCode,
  );
}

class ActionComponentConfigurationDTO {
  final Environment environment;
  final String clientKey;
  final String? shopperLocale;
  final AmountDTO? amount;
  final AnalyticsOptionsDTO analyticsOptionsDTO;

  ActionComponentConfigurationDTO(
    this.environment,
    this.clientKey,
    this.shopperLocale,
    this.amount,
    this.analyticsOptionsDTO,
  );
}

@HostApi()
abstract class CheckoutPlatformInterface {
  @async
  String getReturnUrl();

  @async
  SessionDTO createSession(
    String sessionId,
    String sessionData,
    Object? configuration,
  );

  void invalidateSession();

  @async
  EncryptedCardDTO encryptCard(
    UnencryptedCardDTO unencryptedCardDTO,
    String publicKey,
  );

  @async
  String encryptBin(
    String bin,
    String publicKey,
  );

  void enableConsoleLogging(bool loggingEnabled);
}

@HostApi()
abstract class DropInPlatformInterface {
  // TODO: Merge show dropIn methods into one.
  void showDropInSession(DropInConfigurationDTO dropInConfigurationDTO);

  void showDropInAdvanced(
    DropInConfigurationDTO dropInConfigurationDTO,
    String paymentMethodsResponse,
  );

  void onPaymentsResult(PaymentEventDTO paymentsResult);

  void onPaymentsDetailsResult(PaymentEventDTO paymentsDetailsResult);

  void onDeleteStoredPaymentMethodResult(
      DeletedStoredPaymentMethodResultDTO deleteStoredPaymentMethodResultDTO);

  void cleanUpDropIn();
}

@FlutterApi()
abstract class DropInFlutterInterface {
  void onDropInSessionPlatformCommunication(
      PlatformCommunicationModel platformCommunicationModel);

  void onDropInAdvancedPlatformCommunication(
      PlatformCommunicationModel platformCommunicationModel);
}

@HostApi()
abstract class ComponentPlatformInterface {
  void updateViewHeight(int viewId);

  void onPaymentsResult(
    String componentId,
    PaymentEventDTO paymentsResult,
  );

  void onPaymentsDetailsResult(
    String componentId,
    PaymentEventDTO paymentsDetailsResult,
  );

  @async
  InstantPaymentSetupResultDTO isInstantPaymentSupportedByPlatform(
    InstantPaymentConfigurationDTO instantPaymentConfigurationDTO,
    String paymentMethodResponse,
    String componentId,
  );

  void onInstantPaymentPressed(
    InstantPaymentConfigurationDTO instantPaymentConfigurationDTO,
    String encodedPaymentMethod,
    String componentId,
  );

  void handleAction(
    ActionComponentConfigurationDTO actionComponentConfiguration,
    String componentId,
    Map<String?, Object?>? actionResponse,
  );

  void onDispose(String componentId);
}

@FlutterApi()
abstract class ComponentFlutterInterface {
  // ignore: unused_element
  void _generateCodecForDTOs(
    CardComponentConfigurationDTO cardComponentConfigurationDTO,
    SessionDTO sessionDTO,
  );

  void onComponentCommunication(
      ComponentCommunicationModel componentCommunicationModel);
}
