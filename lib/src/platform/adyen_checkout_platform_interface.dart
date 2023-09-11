import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_api.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class AdyenCheckoutPlatformInterface extends PlatformInterface {
  AdyenCheckoutPlatformInterface() : super(token: _token);

  static final Object _token = Object();
  static AdyenCheckoutPlatformInterface _instance = AdyenCheckoutApi();

  static AdyenCheckoutPlatformInterface get instance => _instance;

  static set instance(AdyenCheckoutPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String> getPlatformVersion();

  Future<String> getReturnUrl();

  void startDropInSessionPayment(
    Session session,
    Configuration dropInConfiguration,
  );

  void startDropInAdvancedFlowPayment(
    String paymentMethodsResponse,
    Configuration dropInConfiguration,
  );

  void onPaymentsResult(DropInResult paymentsResult);

  void onPaymentsDetailsResult(DropInResult paymentsDetailsResult);
}
