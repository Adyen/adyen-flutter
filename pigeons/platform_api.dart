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

enum DropInResultType {
  finished,
  action,
  error,
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
  final String? currency;
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
  final CardsConfigurationDTO? cardsConfigurationDTO;
  final ApplePayConfigurationDTO? applePayConfigurationDTO;
  final GooglePayConfigurationDTO? googlePayConfigurationDTO;
  final CashAppPayConfigurationDTO? cashAppPayConfigurationDTO;
  final AnalyticsOptionsDTO? analyticsOptionsDTO;
  final bool? showPreselectedStoredPaymentMethod;
  final bool? skipListWhenSinglePaymentMethod;
  final bool? isRemoveStoredPaymentMethodEnabled;

  DropInConfigurationDTO(
    this.environment,
    this.clientKey,
    this.countryCode,
    this.amount,
    this.shopperLocale,
    this.cardsConfigurationDTO,
    this.applePayConfigurationDTO,
    this.googlePayConfigurationDTO,
    this.cashAppPayConfigurationDTO,
    this.analyticsOptionsDTO,
    this.showPreselectedStoredPaymentMethod,
    this.skipListWhenSinglePaymentMethod,
    this.isRemoveStoredPaymentMethodEnabled,
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
  final String? resultCode;
  final OrderResponseDTO? order;

  PaymentResultModelDTO(
    this.sessionId,
    this.sessionData,
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

//Use DropInOutcome class when sealed classes are supported by pigeon
class DropInResultDTO {
  final DropInResultType dropInResultType;
  final String? result;
  final Map<String?, Object?>? actionResponse;
  final DropInErrorDTO? error;

  DropInResultDTO({
    required this.dropInResultType,
    this.result,
    this.actionResponse,
    this.error,
  });
}

class DropInErrorDTO {
  final String? errorMessage;
  final String? reason;
  final bool? dismissDropIn;

  DropInErrorDTO({
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

  void onPaymentsResult(DropInResultDTO paymentsResult);

  void onPaymentsDetailsResult(DropInResultDTO paymentsDetailsResult);

  void onDeleteStoredPaymentMethodResult(
      DeletedStoredPaymentMethodResultDTO deleteStoredPaymentMethodResultDTO);
}

@FlutterApi()
abstract class CheckoutFlutterApi {
  void onDropInSessionResult(PaymentResultDTO sessionPaymentResult);

  void onDropInAdvancedFlowPlatformCommunication(
      PlatformCommunicationModel platformCommunicationModel);
}
