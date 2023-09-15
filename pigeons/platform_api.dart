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

class DropInConfigurationDTO {
  final Environment environment;
  final String clientKey;
  final String countryCode;
  final Amount amount;
  final AnalyticsOptionsDTO? analyticsOptionsDTO;
  final bool? showPreselectedStoredPaymentMethod;
  final bool? skipListWhenSinglePaymentMethod;
  final CardsConfigurationDTO? cardsConfigurationDTO;
  final ApplePayConfigurationDTO? applePayConfigurationDTO;

  DropInConfigurationDTO(
    this.environment,
    this.clientKey,
    this.countryCode,
    this.amount,
    this.analyticsOptionsDTO,
    this.cardsConfigurationDTO,
    this.showPreselectedStoredPaymentMethod,
    this.skipListWhenSinglePaymentMethod,
    this.applePayConfigurationDTO,
  );
}

class CardsConfigurationDTO {
  final bool holderNameRequired;
  final AddressMode addressMode;
  final bool showStorePaymentField;
  final bool hideCvcStoredCard;
  final bool hideCvc;
  final bool kcpVisible;
  final bool socialSecurityVisible;
  final List<String?> supportedCardTypes;

  CardsConfigurationDTO(
    this.holderNameRequired,
    this.addressMode,
    this.showStorePaymentField,
    this.hideCvcStoredCard,
    this.hideCvc,
    this.kcpVisible,
    this.socialSecurityVisible,
    this.supportedCardTypes,
  );
}

enum AddressMode {
  full,
  postalCode,
  none,
}

class AnalyticsOptionsDTO {
  final bool? enabled;
  final String? payload;

  AnalyticsOptionsDTO(
    this.enabled,
    this.payload,
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

enum PaymentResultEnum {
  cancelledByUser,
  error,
  finished,
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

enum PlatformCommunicationType {
  paymentComponent,
  additionalDetails,
  result,
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

enum DropInResultType {
  finished,
  action,
  error,
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
