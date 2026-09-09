# Adyen Flutter Checkout 2.0 example

This example demonstrates the Flutter 2.0 alpha Sessions and Advanced flows with the native Adyen
Checkout 6.0.0-alpha.1 SDKs. It uses the generic `CheckoutPaymentComponent` for regular and stored
payment methods and demonstrates the checkout-owned callback lifecycle.

## Requirements

- Flutter 3.24 or later.
- Android API 23 or later with a `FlutterFragmentActivity` host.
- iOS 16 or later with Swift Package Manager enabled.
- An Adyen test account and a backend that exposes Sessions, Payment Methods, Payments, and Payment
  Details endpoints.

## Local configuration

Create an ignored `secrets.json` file in this directory:

```json
{
  "CLIENT_KEY": "YOUR_CLIENT_KEY",
  "X_API_KEY": "YOUR_X_API_KEY",
  "APPLE_PAY_MERCHANT_ID_KEY": "YOUR_APPLE_PAY_MERCHANT_ID_KEY",
  "PUBLIC_KEY": "YOUR_PUBLIC_KEY"
}
```

Run with `--dart-define-from-file=secrets.json`. Never commit this file or embed server credentials
in a production application. `APPLE_PAY_MERCHANT_ID_KEY` must also be supplied as an Xcode build
setting so `ios/Runner/Runner.entitlements` can expand it, and it must match the app's provisioning
profile. A Dart define alone does not populate an Xcode build setting.

## Run

```bash
flutter pub get
flutter run --dart-define-from-file=secrets.json
```

For the Netlify E2E backend use `main_netlify.dart`:

```bash
flutter run --target lib/main_netlify.dart --dart-define-from-file=secrets.json
```

The iOS `AppDelegate` and `SceneDelegate` forward incoming URLs to
`Checkout.handleReturn(url:)`. Configure the same return URL in the backend request and the native
application URL scheme.
