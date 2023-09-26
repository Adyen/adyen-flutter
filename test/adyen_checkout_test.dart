import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/platform/adyen_checkout_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAdyenCheckoutPlatform
    with MockPlatformInterfaceMixin
    implements AdyenCheckoutPlatformInterface {
  @override
  Future<String> getPlatformVersion() => Future.value('42');

  @override
  void startDropInSessionPayment(
      {required SessionDTO session,
      required DropInConfigurationDTO dropInConfiguration}) {
    return;
  }

  @override
  Future<String> getReturnUrl() {
    return Future.value("adyencheckout://com.adyen.adyen_checkout_example");
  }

  @override
  void startDropInAdvancedFlowPayment({
    required String paymentMethodsResponse,
    required DropInConfigurationDTO dropInConfiguration,
  }) {
    return;
  }

  @override
  Future<String> onPaymentsResult(DropInResultDTO paymentsResult) =>
      Future.value("Result");

  @override
  Future<void> onPaymentsDetailsResult(DropInResultDTO paymentsDetailsResult) {
    return Future.value(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final AdyenCheckout initialPlatform = AdyenCheckout();

  test('$AdyenCheckout is the default instance', () {
    expect(initialPlatform, isInstanceOf<AdyenCheckout>());
  });

  test('getPlatformVersion', () async {
    AdyenCheckout adyenCheckoutPlugin = AdyenCheckout();
    MockAdyenCheckoutPlatform fakePlatform = MockAdyenCheckoutPlatform();
    AdyenCheckoutPlatformInterface.instance = fakePlatform;

    expect(await adyenCheckoutPlugin.getPlatformVersion(), '42');
  });
}
