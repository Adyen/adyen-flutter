# Localization

Checkout 2.0 alpha delegates shopper-facing strings to the native Adyen v6 SDKs. The Flutter
configuration does not expose `shopperLocale`; native defaults are used for the active platform.

To override strings, define the relevant native resources in your application:

- Android: override Checkout string resources in `android/app/src/main/res/values/strings.xml` and
  localized value directories.
- iOS: add the Adyen localization keys to the application's string catalog.

Payment-method names and checkout UI text are owned by the native v6 components in this alpha.
