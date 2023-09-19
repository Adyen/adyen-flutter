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

enum PaymentResultEnum {
  cancelledByUser,
  error,
  finished,
}

enum PlatformCommunicationType {
  paymentComponent,
  additionalDetails,
  result,
}

enum DropInResultType {
  finished,
  action,
  error,
}

enum CashAppPayEnvironment {
  sandbox,
  production,
}

class Session {
  final String id;
  final String sessionData;

  Session({
    required this.id,
    required this.sessionData,
  });
}

class Amount {
  final String? currency;
  final int value;

  Amount({
    required this.currency,
    required this.value,
  });
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
  final Amount amount;
  final String shopperLocale;
  final AnalyticsOptionsDTO? analyticsOptionsDTO;
  final bool? showPreselectedStoredPaymentMethod;
  final bool? skipListWhenSinglePaymentMethod;
  final CardsConfigurationDTO? cardsConfigurationDTO;
  final ApplePayConfigurationDTO? applePayConfigurationDTO;
  final GooglePayConfigurationDTO? googlePayConfigurationDTO;
  final CashAppPayConfigurationDTO? cashAppPayConfigurationDTO;

  DropInConfigurationDTO(
    this.environment,
    this.clientKey,
    this.countryCode,
    this.amount,
    this.shopperLocale,
    this.analyticsOptionsDTO,
    this.cardsConfigurationDTO,
    this.showPreselectedStoredPaymentMethod,
    this.skipListWhenSinglePaymentMethod,
    this.applePayConfigurationDTO,
    this.googlePayConfigurationDTO,
    this.cashAppPayConfigurationDTO,
  );
}

class CardsConfigurationDTO {
  final bool holderNameRequired;
  final AddressMode addressMode;
  final bool showStorePaymentField;
  final bool showCvcForStoredCard;
  final bool showCvc;
  final bool showKcpField;
  final bool showSocialSecurityNumberField;
  final List<String?> supportedCardTypes;

  CardsConfigurationDTO(
    this.holderNameRequired,
    this.addressMode,
    this.showStorePaymentField,
    this.showCvcForStoredCard,
    this.showCvc,
    this.showKcpField,
    this.showSocialSecurityNumberField,
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
  final String merchantAccount;
  final List<String?> allowedCardNetworks;
  final List<String?> allowedAuthMethods;
  final TotalPriceStatus totalPriceStatus;
  final bool allowPrepaidCards;
  final bool billingAddressRequired;
  final bool emailRequired;
  final bool shippingAddressRequired;
  final bool existingPaymentMethodRequired;
  final GooglePayEnvironment googlePayEnvironment;

  GooglePayConfigurationDTO(
    this.totalPriceStatus,
    this.googlePayEnvironment,
    this.merchantAccount,
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

  CashAppPayConfigurationDTO(this.cashAppPayEnvironment);
}

class PaymentResult {
  final PaymentResultEnum type;
  final String? reason;
  final PaymentResultModel? result;

  PaymentResult(
    this.type,
    this.reason,
    this.result,
  );
}

class PaymentResultModel {
  final String? sessionId;
  final String? sessionData;
  final String? resultCode;
  final OrderResponseModel? order;

  PaymentResultModel(
    this.sessionId,
    this.sessionData,
    this.resultCode,
    this.order,
  );
}

class OrderResponseModel {
  final String pspReference;
  final String orderData;
  final Amount? amount;
  final Amount? remainingAmount;

  OrderResponseModel({
    required this.pspReference,
    required this.orderData,
    this.amount,
    this.remainingAmount,
  });
}

class PlatformCommunicationModel {
  final PlatformCommunicationType type;
  final String? data;
  final PaymentResult? paymentResult;

  PlatformCommunicationModel({
    required this.type,
    this.data,
    this.paymentResult,
  });
}

//Use DropInOutcome class when sealed classes are supported by pigeon
class DropInResult {
  final DropInResultType dropInResultType;
  final String? result;
  final Map<String?, Object?>? actionResponse;
  final DropInError? error;

  DropInResult({
    required this.dropInResultType,
    this.result,
    this.actionResponse,
    this.error,
  });
}

class DropInError {
  final String? errorMessage;
  final String? reason;
  final bool? dismissDropIn;

  DropInError({
    this.errorMessage,
    this.reason,
    this.dismissDropIn = false,
  });
}

@HostApi()
abstract class CheckoutPlatformInterface {
  @async
  String getPlatformVersion();

  @async
  String getReturnUrl();

  void startDropInSessionPayment(
    DropInConfigurationDTO dropInConfigurationDTO,
    Session session,
  );

  void startDropInAdvancedFlowPayment(
    DropInConfigurationDTO dropInConfigurationDTO,
    String paymentMethodsResponse,
  );

  void onPaymentsResult(DropInResult paymentsResult);

  void onPaymentsDetailsResult(DropInResult paymentsDetailsResult);
}

@FlutterApi()
abstract class CheckoutFlutterApi {
  void onDropInSessionResult(PaymentResult sessionPaymentResult);

  void onDropInAdvancedFlowPlatformCommunication(
      PlatformCommunicationModel platformCommunicationModel);
}
