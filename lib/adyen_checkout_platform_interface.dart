import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'adyen_checkout_method_channel.dart';

abstract class AdyenCheckoutPlatform extends PlatformInterface {
  /// Constructs a AdyenCheckoutPlatform.
  AdyenCheckoutPlatform() : super(token: _token);

  static final Object _token = Object();

  static AdyenCheckoutPlatform _instance = MethodChannelAdyenCheckout();

  /// The default instance of [AdyenCheckoutPlatform] to use.
  ///
  /// Defaults to [MethodChannelAdyenCheckout].
  static AdyenCheckoutPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AdyenCheckoutPlatform] when
  /// they register themselves.
  static set instance(AdyenCheckoutPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
