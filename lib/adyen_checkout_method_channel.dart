import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'adyen_checkout_platform_interface.dart';

/// An implementation of [AdyenCheckoutPlatform] that uses method channels.
class MethodChannelAdyenCheckout extends AdyenCheckoutPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('adyen_checkout');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
