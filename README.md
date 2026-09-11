![Flutter](https://github.com/Adyen/adyen-flutter/assets/13377878/66a9fab8-dba0-426f-acd4-ab0bfd469d20)

# Adyen Flutter Checkout 2.0

[![Pub Package](https://img.shields.io/pub/v/adyen_checkout.svg)](https://pub.dev/packages/adyen_checkout)
[![Adyen iOS](https://img.shields.io/badge/ios-v6.0.0--alpha.1-brightgreen.svg)](https://github.com/Adyen/adyen-ios/releases/tag/6.0.0-alpha.1)
[![Adyen Android](https://img.shields.io/badge/android-v6.0.0--alpha.1-brightgreen.svg)](https://github.com/Adyen/adyen-android/releases/tag/6.0.0-alpha.1)

This prerelease provides a Flutter wrapper around the public Adyen Checkout v6 APIs. It supports
Sessions, Advanced integrations, generic native payment components, and one-shot action handling.

The first release is `2.0.0-alpha.1` because the native SDK dependencies are alpha releases.

## Supported flows

- **Sessions**: the native SDK handles the `/sessions` payment lifecycle.
- **Advanced**: your callbacks handle `/payments` and `/payments/details`.
- **Action-only**: `Checkout.instance.handleAction` handles an action returned by your backend.
- **Payment components**: `CheckoutPaymentComponent` renders the selected native payment method.
  Card, stored cards, BLIK, Google Pay on Android, Apple Pay on iOS, and native direct methods use
  the same generic component API. On iOS, Apple Pay temporarily renders `PKPaymentButton` inside the
  platform view until native Checkout provides its own button; this does not add a separate public component.
- **Card utilities**: client-side encryption and card validation remain on `Checkout`.

Drop-in, separate Instant APIs, partial payments, checkout theming, and web or desktop platforms are
not part of this alpha.

## Requirements

- Flutter `>=3.24.0` and Dart `>=3.5.0`.
- Android API 23 or later and a `FlutterFragmentActivity` host.
- iOS 16.0 or later.
- iOS integration through Swift Package Manager. Flutter 3.24–3.43 projects must opt in to SwiftPM;
  Flutter 3.44 and later enables it by default.
- Checkout API v71 or later.

Configure your backend return URL and forward incoming native returns to the native Checkout API:

```swift
func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
) -> Bool {
    Checkout.handleReturn(url: url) || super.application(application, open: url, options: options)
}
```

Android hosts forward new intents to the active checkout controller through the plugin. The Flutter
package intentionally does not provide a return-URL generator; merchants configure the URL with their
backend and app URL scheme.

## Sessions

```dart
final checkout = await Checkout.instance.setup(
  sessionResponse: SessionResponse(
    id: sessionJson['id'] as String,
    sessionData: sessionJson['sessionData'] as String,
  ),
  configuration: configuration,
  callbacks: SessionCheckoutCallbacks(
    onComplete: (result) => consumeSessionResult(result.sessionResult),
    onFailure: handleCheckoutError,
  ),
);

CheckoutPaymentComponent(
  checkout: checkout,
  paymentMethod: checkout.paymentMethods.first,
);
```

## Advanced

```dart
final checkout = await Checkout.instance.setupAdvanced(
  paymentMethods: PaymentMethods.fromJson(paymentMethodsJson),
  configuration: configuration,
  callbacks: AdvancedCheckoutCallbacks(
    onSubmit: (data) async =>
        SubmitResult.completion(resultCode: 'Authorised'),
    onAdditionalDetails: (data) async =>
        AdditionalDetailsResult.completion(resultCode: 'Authorised'),
    onComplete: handleAdvancedResult,
    onFailure: handleCheckoutError,
  ),
);
```

Use an optional `CheckoutController` for a custom submit button or direct/no-input payment methods.
It exposes `isReady`, `requiresUserInteraction`, `submit()`, and lifecycle state. A controller is
required when `showSubmitButton` is `false` or the selected native method does not require shopper
input.

The v1 Instant methods—iDEAL, PayPal, Klarna, Pay by Bank, and TWINT—use this same generic component.
Keep the component mounted while native Checkout owns the payment and action lifecycle. When native
reports that no interaction is required, the platform view collapses to zero height and a merchant
button can submit through the controller:

```dart
final controller = CheckoutController();
bool submitted = false;

Column(
  children: [
    CheckoutPaymentComponent(
      checkout: checkout,
      paymentMethod: paymentMethod,
      controller: controller,
    ),
    ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final canSubmit = controller.isReady &&
            controller.requiresUserInteraction == false &&
            !submitted;
        if (controller.requiresUserInteraction != false) {
          return const SizedBox.shrink();
        }
        return FilledButton(
          onPressed: canSubmit
              ? () async {
                  setState(() => submitted = true);
                  await controller.submit();
                }
              : null,
          child: Text('Pay with ${paymentMethod.name}'),
        );
      },
    ),
  ],
);
```

Dispose a merchant-created controller with the owning widget. Do not classify payment method types
in application code. With the pinned alpha.1 native SDKs, use
`requiresUserInteraction` as the native-authoritative signal. Future native SDK versions are
expected to render their own payment button; a future dependency update will replace this temporary
CTA with the native UI without changing the merchant-facing Flutter component/controller API.

## Configuration

`CheckoutConfiguration` accepts the shared environment, client key, optional amount and country
code, analytics configuration, submit-button visibility, and the applicable Card, Apple Pay, or
Google Pay configuration. Unsupported native options are intentionally not exposed.

## Migration

Flutter 2.0 is a breaking release and is not source-compatible with Flutter 1.x. See
[`MIGRATION.md`](MIGRATION.md) for the API mapping and removed integrations.

## Support

For issues, create a GitHub issue or contact Adyen Support through the Customer Area.

## License

MIT license. See [LICENSE](LICENSE).
