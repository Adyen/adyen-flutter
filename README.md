![Flutter](https://github.com/Adyen/adyen-flutter/assets/13377878/66a9fab8-dba0-426f-acd4-ab0bfd469d20)

# Adyen Flutter Checkout 2.0

[![Pub Package](https://img.shields.io/pub/v/adyen_checkout.svg)](https://pub.dev/packages/adyen_checkout)
[![Adyen iOS](https://img.shields.io/badge/ios-develop%20%40%20e309205-brightgreen.svg)](https://github.com/Adyen/adyen-ios/commit/e3092053f15139146b248d1a90ecef0cf0adbf70)
[![Adyen Android](https://img.shields.io/badge/android-snapshot%202026.11.08-brightgreen.svg)](https://central.sonatype.com/repository/maven-snapshots/com/adyen/checkout/core/)

This prerelease provides a Flutter wrapper around the public Adyen Checkout v6 APIs. It supports
Sessions, generic native payment components, and one-shot action handling.

The first release is `2.0.0-alpha.1` because the native SDK dependencies are alpha releases.

## Supported flows

- **Sessions**: the native SDK handles the `/sessions` payment lifecycle.
- **Action-only**: `AdyenCheckout.instance.handleAction` handles an action returned by your backend.
- **Payment components**: `CheckoutPaymentComponent` renders the selected native payment method.
  Card, stored cards, BLIK, Google Pay on Android, Apple Pay on iOS, and native direct methods use
  the same generic component API. On iOS, Apple Pay renders the native SDK's Apple Pay button, styled
  with `ApplePayButtonStyle`. The button fills the component width and has a fixed height; wrap
  `CheckoutPaymentComponent` in a `SizedBox` to control its width. `buttonWidth` and `buttonHeight`
  are deprecated and ignored until the native iOS SDK supports a custom button size.
- **Card utilities**: client-side encryption and card validation remain on `AdyenCheckout`.

Drop-in, separate Instant APIs, partial payments, checkout theming, and web or desktop platforms are
not part of this alpha.

## Requirements

- Flutter `>=3.27.0` and Dart `>=3.6.0`.
- Android API 23 or later and a `FlutterFragmentActivity` host.
- iOS 16.0 or later.
- iOS integration through Swift Package Manager only; CocoaPods is no longer supported. Flutter
  3.27–3.43 projects must opt in to SwiftPM; Flutter 3.44 and later enables it by default. Use
  [adyen_checkout 1.15.0](https://pub.dev/packages/adyen_checkout/versions/1.15.0) as the last
  version for CocoaPods.
- Checkout API v71 or later.
- AGP 9 is supported with built-in Kotlin disabled (requires Flutter 3.44 or later). Built-in
  Kotlin is not supported yet. Make sure `android/gradle.properties` contains
  `android.builtInKotlin=false` and `android.newDsl=false`; Flutter adds them automatically when
  creating or migrating a project. See the [example app](example/android/gradle.properties).

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
final checkout = await AdyenCheckout.instance.setup(
  sessionResponse: SessionResponse(
    id: sessionJson['id'] as String,
    sessionData: sessionJson['sessionData'] as String,
  ),
  configuration: configuration,
  callbacks: CheckoutCallbacks(
    onComplete: (result) => consumeSessionResult(result.sessionResult),
    onFailure: handleCheckoutError,
  ),
);

CheckoutPaymentComponent(
  checkout: checkout,
  paymentMethod: checkout.paymentMethods.first,
);
```

Payment-method callbacks are passed through `CheckoutCallbacks`, like the native v6 SDKs:
`CheckoutCallbacks(card: CardCallbacks(onBinLookup: ...), applePay: ApplePayCallbacks(onAuthorize: ...))`.

Native components render their own submit button by default. The v1 Instant methods—iDEAL, PayPal,
Klarna, Pay by Bank, and TWINT—use this same generic component and show a native pay button inside
the platform view; no Flutter-side button is needed. Keep the component mounted while native
Checkout owns the payment and action lifecycle.

```dart
CheckoutPaymentComponent(
  checkout: checkout,
  paymentMethod: paymentMethod,
);
```

Use an optional `CheckoutController` when `showSubmitButton` is `false` (custom merchant button) or
for programmatic submission. It exposes `isReady`, `requiresUserInteraction`, `submit()`, and
lifecycle state. When `showSubmitButton` is `false`, direct/no-input methods collapse to zero
height and the merchant's own button submits through the controller. Dispose a merchant-created
controller with the owning widget.

## Configuration

`CheckoutConfiguration` accepts the shared environment, client key, analytics configuration,
submit-button visibility, and the applicable Card, Apple Pay, or Google Pay configuration. The
amount and country code live on the payment methods that need them: `ApplePayConfiguration`
(`amount`, `countryCode`) and `GooglePayConfiguration` (`countryCode`). Sessions supply the amount
natively. Unsupported native options are intentionally not exposed.

## Migration

Flutter 2.0 is a breaking release and is not source-compatible with Flutter 1.x. See
[`MIGRATION.md`](MIGRATION.md) for the API mapping and removed integrations.

## Support

For issues, create a GitHub issue or contact Adyen Support through the Customer Area.

## License

MIT license. See [LICENSE](LICENSE).
