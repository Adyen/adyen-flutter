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

  void startDropInSessionPayment({
    required SessionDTO session,
    required DropInConfigurationDTO dropInConfiguration,
  });

  void startDropInAdvancedFlowPayment({
    required String paymentMethodsResponse,
    required DropInConfigurationDTO dropInConfiguration,
  });

  void onPaymentsResult(DropInResultDTO paymentsResult);

  void onPaymentsDetailsResult(DropInResultDTO paymentsDetailsResult);

  void onDeleteStoredPaymentMethodResult(
      DeletedStoredPaymentMethodResultDTO deleteStoredPaymentMethodResultDTO);

  void enableLogging(bool loggingEnabled);

  void cleanUpDropIn();
}
