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

class DropInConfiguration {
  final Environment environment;
  final String clientKey;
  final Amount amount;
  final String countryCode;
  bool? isAnalyticsEnabled;
  bool? showPreselectedStoredPaymentMethod;
  bool? skipListWhenSinglePaymentMethod;
  bool? isRemovingStoredPaymentMethodsEnabled;
  String? additionalDataForDropInService;

  DropInConfiguration({
    required this.environment,
    required this.clientKey,
    required this.amount,
    required this.countryCode,
  });
}

class PaymentResult {
  final PaymentResultEnum type;
  final String? reason;
  final SessionPaymentResultModel? result;

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

// sealed class DropInResult {}
//
// class Finished extends DropInResult {
//   final String result;
//
//   Finished(this.result);
// }

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

  void startDropInSessionPayment(
    DropInConfiguration dropInConfiguration,
    Session session,
  );

  void startDropInAdvancedFlowPayment(
    DropInConfiguration dropInConfiguration,
    String paymentMethodsResponse,
  );

  void onPaymentsResult(Map<String, Object?> paymentsResult);

  void onPaymentsDetailsResult(Map<String, Object?> paymentsDetailsResult);
}

@FlutterApi()
abstract class CheckoutFlutterApi {
  void onDropInSessionResult(PaymentResult sessionDropInResult);

  void onDropInAdvancedFlowPlatformCommunication(
      PlatformCommunicationModel platformCommunicationModel);
}
