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
  final String shopperLocale;
  bool? isAnalyticsEnabled;
  bool? showPreselectedStoredPaymentMethod;
  bool? skipListWhenSinglePaymentMethod;
  bool? isRemovingStoredPaymentMethodsEnabled;
  String? additionalDataForDropInService;

  DropInConfigurationModel({
    required this.environment,
    required this.clientKey,
    required this.amount,
    required this.shopperLocale,
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

class SessionDropInResultModel {
  final SessionDropInResultEnum sessionDropInResult;
  final String? reason;
  final SessionPaymentResultModel? result;

  SessionDropInResultModel(
    this.sessionDropInResult,
    this.reason,
    this.result,
  );
}

enum SessionDropInResultEnum {
  cancelledByUser,
  error,
  finished,
}

// class DropInAdvancedFlowResultModel {
//   final String? result;
//   final ActionModel? action;
//   final ErrorModel? error;
//
//   DropInAdvancedFlowResultModel(
//     this.result,
//     this.action,
//     this.error,
//   );
// }
//
// enum DropInServiceResultEnum {
//   finished,
//   action,
//   update,
//   error,
// }
//
// class ActionModel {
//   final String? type;
//   final String? paymentData;
//   final String? paymentMethodType;
//
//   ActionModel(
//     this.type,
//     this.paymentData,
//     this.paymentMethodType,
//   );
// }
//
// class ErrorModel {
//   final String? errorMessage;
//   final String? reason;
//   final bool dismissDropIn;
//
//   ErrorModel(
//     this.errorMessage,
//     this.reason,
//     this.dismissDropIn,
//   );
// }

@HostApi()
abstract class CheckoutPlatformInterface {
  @async
  String getPlatformVersion();

  @async
  void startPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  );

  String getReturnUrl();

  @async
  String startPaymentDropInAdvancedFlow(
    String paymentMethodsResponse,
    DropInConfigurationModel dropInConfiguration,
  );

  @async
  String? onPaymentsResult(Map<String, Object?> paymentsResult);

  @async
  void onPaymentsDetailsResult(Map<String, Object?> paymentsDetailsResult);
}

@FlutterApi()
abstract class CheckoutResultFlutterInterface {
  void onSessionDropInResult(SessionDropInResultModel sessionDropInResult);

  void onDropInAdvancedFlowResult(
      SessionDropInResultModel dropInAdvancedFlowResult);
}
