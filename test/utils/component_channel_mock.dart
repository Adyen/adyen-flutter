import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pigeon message channels used by the component platform interfaces.
abstract final class ComponentChannels {
  static const availability =
      'dev.flutter.pigeon.adyen_checkout.ComponentPlatformInterface.isInstantPaymentSupportedByPlatform';
  static const paymentsResult =
      'dev.flutter.pigeon.adyen_checkout.ComponentPlatformInterface.onPaymentsResult';
  static const dispose =
      'dev.flutter.pigeon.adyen_checkout.ComponentPlatformInterface.onDispose';
  static const instantPaymentPressed =
      'dev.flutter.pigeon.adyen_checkout.ComponentPlatformInterface.onInstantPaymentPressed';
  static const componentCommunication =
      'dev.flutter.pigeon.adyen_checkout.ComponentFlutterInterface.onComponentCommunication';
}

/// Replaces the platform side of a Pigeon [channel].
///
/// Every incoming message is decoded, appended to [capturedMessages] and
/// answered with `respond`'s return value (defaults to `[null]`).
void mockPigeonChannel(
  String channel, {
  List<Object?> Function(List<Object?> message)? respond,
  List<List<Object?>>? capturedMessages,
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(
    BasicMessageChannel<Object?>(
      channel,
      ComponentPlatformInterface.pigeonChannelCodec,
    ),
    (message) async {
      final decoded = message! as List<Object?>;
      capturedMessages?.add(decoded);
      return respond?.call(decoded) ?? <Object?>[null];
    },
  );
}

void unmockPigeonChannel(String channel) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockDecodedMessageHandler<Object?>(
    BasicMessageChannel<Object?>(
      channel,
      ComponentPlatformInterface.pigeonChannelCodec,
    ),
    null,
  );
}
