import 'package:adyen_checkout/src/adyen_checkout.dart';
import 'package:adyen_checkout/src/adyen_checkout_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAdyenCheckoutPlatform
    with MockPlatformInterfaceMixin
    implements AdyenCheckoutPlatformInterface {

  @override
  Future<String> getPlatformVersion() => Future.value('42');
}

void main() {
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
