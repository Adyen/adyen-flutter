import 'package:adyen_checkout/src/components/apple_pay/apple_pay_callback_handler.dart';

/// Routes Apple Pay callbacks from the single Pigeon entry point on
/// [ComponentFlutterApi] to the [ApplePayCallbackHandler] owned by the
/// component instance, keyed by `componentId`.
///
/// This avoids the previous static `_applePayConfiguration` field that did not
/// support multiple Apple Pay components alive at the same time.
class ApplePayCallbackRegistry {
  ApplePayCallbackRegistry._();

  static final ApplePayCallbackRegistry instance = ApplePayCallbackRegistry._();

  final Map<String, ApplePayCallbackHandler> _handlers = {};

  void register(String componentId, ApplePayCallbackHandler handler) {
    _handlers[componentId] = handler;
  }

  void unregister(String componentId) {
    _handlers.remove(componentId);
  }

  ApplePayCallbackHandler? handlerFor(String componentId) =>
      _handlers[componentId];
}
