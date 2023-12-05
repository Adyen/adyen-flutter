import 'package:pigeon/pigeon.dart';

//dart run pigeon --input pigeons/platform_api.dart
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/generated/platform_api.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/src/main/kotlin/com/adyen/adyen_checkout/PlatformApi.kt',
  kotlinOptions: KotlinOptions(),
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
  result,
  error,
  resize,
}

enum PaymentFlowResultType {
  finished,
  action,
  error,
}

enum FieldVisibility {
  show,
  hide,
}

class SessionDTO {
  final String id;
  final String sessionData;

  SessionDTO(
    this.id,
    this.sessionData,
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
  final bool? enabled;
  final String? payload;

  AnalyticsOptionsDTO(
    this.enabled,
    this.payload,
  );
}

class DropInConfigurationDTO {
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final AmountDTO amount;
  final String shopperLocale;
  final CardConfigurationDTO? cardConfigurationDTO;
  final ApplePayConfigurationDTO? applePayConfigurationDTO;
  final GooglePayConfigurationDTO? googlePayConfigurationDTO;
  final CashAppPayConfigurationDTO? cashAppPayConfigurationDTO;
  final AnalyticsOptionsDTO? analyticsOptionsDTO;
  final bool showPreselectedStoredPaymentMethod;
  final bool skipListWhenSinglePaymentMethod;
  final bool isRemoveStoredPaymentMethodEnabled;

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
  final bool allowOnboarding;

  ApplePayConfigurationDTO(
    this.merchantId,
    this.merchantName,
    this.allowOnboarding,
  );
}

class GooglePayConfigurationDTO {
  final GooglePayEnvironment googlePayEnvironment;
  final String? merchantAccount;
  final List<String?> allowedCardNetworks;
  final List<String?> allowedAuthMethods;
  final TotalPriceStatus? totalPriceStatus;
  final bool allowPrepaidCards;
  final bool billingAddressRequired;
  final bool emailRequired;
  final bool shippingAddressRequired;
  final bool existingPaymentMethodRequired;

  GooglePayConfigurationDTO(
    this.googlePayEnvironment,
    this.merchantAccount,
    this.totalPriceStatus,
    this.allowedCardNetworks,
    this.allowedAuthMethods,
    this.allowPrepaidCards,
    this.billingAddressRequired,
    this.emailRequired,
    this.shippingAddressRequired,
    this.existingPaymentMethodRequired,
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
  final Object? data;
  final PaymentResultModelDTO? paymentResult;

  ComponentCommunicationModel({
    required this.type,
    this.data,
    this.paymentResult,
  });
}

//Use PaymentFlowOutcome class when sealed classes are supported by pigeon
class PaymentFlowOutcomeDTO {
  final PaymentFlowResultType paymentFlowResultType;
  final String? result;
  final Map<String?, Object?>? actionResponse;
  final ErrorDTO? error;

  PaymentFlowOutcomeDTO({
    required this.paymentFlowResultType,
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
  final AmountDTO amount;
  final String? shopperLocale;
  final CardConfigurationDTO cardConfiguration;

  CardComponentConfigurationDTO(
    this.environment,
    this.clientKey,
    this.countryCode,
    this.amount,
    this.shopperLocale,
    this.cardConfiguration,
  );
}

@HostApi()
abstract class CheckoutPlatformInterface {
  @async
  String getPlatformVersion();

  @async
  String getReturnUrl();

  void startDropInSessionPayment(
    DropInConfigurationDTO dropInConfigurationDTO,
    SessionDTO session,
  );

  void startDropInAdvancedFlowPayment(
    DropInConfigurationDTO dropInConfigurationDTO,
    String paymentMethodsResponse,
  );

  void onPaymentsResult(PaymentFlowOutcomeDTO paymentsResult);

  void onPaymentsDetailsResult(PaymentFlowOutcomeDTO paymentsDetailsResult);

  void onDeleteStoredPaymentMethodResult(
      DeletedStoredPaymentMethodResultDTO deleteStoredPaymentMethodResultDTO);

  void enableLogging(bool loggingEnabled);

  void cleanUpDropIn();
}

@FlutterApi()
abstract class CheckoutFlutterApi {
  void onDropInSessionPlatformCommunication(
      PlatformCommunicationModel platformCommunicationModel);

  void onDropInAdvancedFlowPlatformCommunication(
      PlatformCommunicationModel platformCommunicationModel);
}

@HostApi()
abstract class ComponentPlatformInterface {
  void updateViewHeight(int viewId);

  void onPaymentsResult(PaymentFlowOutcomeDTO paymentsResult);

  void onPaymentsDetailsResult(PaymentFlowOutcomeDTO paymentsDetailsResult);
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
