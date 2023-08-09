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
  test(url: "https://checkoutshopper-test.adyen.com/checkoutshopper/"),
  europe(url: "https://checkoutshopper-live.adyen.com/checkoutshopper/"),
  unitedStates(
      url: "https://checkoutshopper-live-us.adyen.com/checkoutshopper/"),
  australia(url: "https://checkoutshopper-live-au.adyen.com/checkoutshopper/"),
  india(url: "https://checkoutshopper-live-in.adyen.com/checkoutshopper/"),
  apse(url: "https://checkoutshopper-live-apse.adyen.com/checkoutshopper/");

  final String url;

  const Environment({required this.url});
}

class SessionModel {
  final String id;
  final String sessionData;

  SessionModel({required this.id, required this.sessionData});
}

class Amount {
  final String currency;
  final double value;

  Amount({required this.currency, required this.value});
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
  Locale? shopperLocale;
  final Environment environment;
  final String clientKey;
  final Amount amount;
  bool? isAnalyticsEnabled;
  bool? showPreselectedStoredPaymentMethod;
  bool? skipListWhenSinglePaymentMethod;
  bool? isRemovingStoredPaymentMethodsEnabled;
  String? additionalDataForDropInService;

  DropInConfigurationModel({
    required this.environment,
    required this.clientKey,
    required this.amount,
  });
}

class OrderResponse {
  final String pspReference;
  final String orderData;
  final Amount? amount;
  final Amount? remainingAmount;

  OrderResponse({
    required this.pspReference,
    required this.orderData,
    this.amount,
    this.remainingAmount,
  });
}

class SessionDropInResult {
  final SessionDropInResultEnum sessionDropInResult;
  final String data;

  SessionDropInResult(this.sessionDropInResult, this.data);
}

enum SessionDropInResultEnum {
  cancelledByUser,
  error,
  finished,
}

@HostApi()
abstract class CheckoutPlatformApi {
  @async
  String getPlatformVersion();

  @async
  void startPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  );
}
