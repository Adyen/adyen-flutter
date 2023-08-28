import 'package:pigeon/pigeon.dart';

//dart run pigeon --input pigeons/platform_api.dart
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/platform_api.g.dart',
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

class SessionModel {
  final String id;
  final String sessionData;

  SessionModel({
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

enum Locale {
  canada,
  canadaFrench,
  china,
  chinese,
  english,
  france,
  french,
  german,
  germany,
  italian,
  italy,
  japan,
  japanese,
  korea,
  korean,
  //Do we need to support prc and root?
  prc,
  root,
  simplifiedChinese,
  taiwan,
  traditionalChinese,
  uk,
  us
}

class DropInConfigurationModel {
  final Environment environment;
  final String clientKey;
  final Amount amount;
  final String countryCode;
  bool? isAnalyticsEnabled;
  bool? showPreselectedStoredPaymentMethod;
  bool? skipListWhenSinglePaymentMethod;
  bool? isRemovingStoredPaymentMethodsEnabled;
  String? additionalDataForDropInService;

  DropInConfigurationModel({
    required this.environment,
    required this.clientKey,
    required this.amount,
    required this.countryCode,
  });
}

class SessionPaymentResultModel {
  final String? sessionId;
  final String? sessionData;
  final String? resultCode;
  final OrderResponseModel? order;

  SessionPaymentResultModel(
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

class DropInResultModel {
  final DropInResultEnum sessionDropInResult;
  final String? reason;
  final SessionPaymentResultModel? result;

  DropInResultModel(
    this.sessionDropInResult,
    this.reason,
    this.result,
  );
}

enum DropInResultEnum {
  cancelledByUser,
  error,
  finished,
}

class PlatformCommunicationModel {
  final PlatformCommunicationType type;
  final String? data;
  final DropInResultModel? result;

  PlatformCommunicationModel({
    required this.type,
    this.data,
    this.result,
  });
}

enum PlatformCommunicationType {
  paymentComponent,
  additionalDetails,
  result,
}

@HostApi()
abstract class CheckoutPlatformInterface {
  @async
  String getPlatformVersion();

  @async
  String getReturnUrl();

  void startPayment(
    DropInConfigurationModel dropInConfiguration,
    SessionModel sessionModel,
  );

  void startPaymentDropInAdvancedFlow(
    DropInConfigurationModel dropInConfiguration,
    String paymentMethodsResponse,
  );

  void onPaymentsResult(Map<String, Object?> paymentsResult);

  void onPaymentsDetailsResult(Map<String, Object?> paymentsDetailsResult);
}

@FlutterApi()
abstract class CheckoutFlutterApi {
  void onDropInSessionResult(DropInResultModel sessionDropInResult);

  void onDropInAdvancedFlowPlatformCommunication(
      PlatformCommunicationModel platformCommunicationModel);
}
