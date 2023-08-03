import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/adyen_checkout_method_channel.dart';
import 'package:adyen_checkout/adyen_checkout_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAdyenCheckoutPlatform
    with MockPlatformInterfaceMixin
    implements AdyenCheckoutPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AdyenCheckoutPlatform initialPlatform = AdyenCheckoutPlatform.instance;

  test('$MethodChannelAdyenCheckout is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAdyenCheckout>());
  });

  test('getPlatformVersion', () async {
    AdyenCheckout adyenCheckoutPlugin = AdyenCheckout();
    MockAdyenCheckoutPlatform fakePlatform = MockAdyenCheckoutPlatform();
    AdyenCheckoutPlatform.instance = fakePlatform;

    expect(await adyenCheckoutPlugin.getPlatformVersion(), '42');
  });
}
