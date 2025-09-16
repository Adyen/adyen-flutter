![Flutter](https://github.com/Adyen/adyen-flutter/assets/13377878/66a9fab8-dba0-426f-acd4-ab0bfd469d20)

# Adyen Flutter

[![Pub Package](https://img.shields.io/pub/v/adyen_checkout.svg)](https://pub.dev/packages/adyen_checkout)
[![Adyen iOS](https://img.shields.io/badge/ios-v5.20.0-brightgreen.svg)](https://github.com/Adyen/adyen-ios/releases/tag/5.20.0)
[![Adyen Android](https://img.shields.io/badge/android-v5.14.0-brightgreen.svg)](https://github.com/Adyen/adyen-android/releases/tag/5.14.0)

The Adyen Flutter package provides you with the building blocks to create a checkout experience for
your shoppers, allowing them to pay using the payment method of their choice. This is
an [overview](https://docs.adyen.com/payment-methods/) of the payment methods that you can add to
your online payments integration.

You can integrate with the following:

* **Drop-in**: an out-of-the-box Flutter wrapper for native iOS and Android Drop-in that includes
  all available payment methods for your shoppers to choose.
* **Components**: Flutter widgets for native iOS and Android Adyen Components. You use one Component
  for each payment method. We currently offer the following Components:
    - Card Component: allows shoppers to pay with card. Stored cards are also supported.
    - Google Pay Component: renders a Google Pay button.
    - Apple Pay Component: renders an Apple Pay button.
    - Instant Component: supports payment methods that do not require additional input fields, like
      PayPal, Klarna and many more.
* **API only**: Build your own UI for the card payment form, collect the shopper's card details, and
  then use the package to validate and encrypt the card data in your app.

|                                                                iOS                                                                 |                                                              Android                                                               |
|:----------------------------------------------------------------------------------------------------------------------------------:|:----------------------------------------------------------------------------------------------------------------------------------:|
| <img align="top" src="https://github.com/Adyen/adyen-flutter/assets/13377878/4a1d623b-5f82-49f1-b18d-84a7b2c06d63" height="600" /> | <img align="top" src="https://github.com/Adyen/adyen-flutter/assets/13377878/0bce3d67-8d33-4ecc-a6e2-6e409d1ac876" height="600" /> |

## Contributing

Follow our [guidelines](https://github.com/Adyen/.github/blob/main/CONTRIBUTING.md) to provide
feedback and contribute the following to this repository:

* New features and functionality
* Bug fixes and resolved issues
* General improvements

We merge each pull request into the `main` branch. We aim to keep it in good shape so that we can
release a new version when we need to.

## Before you begin

1. [Get an Adyen test account](https://www.adyen.com/signup).
2. [Get your Client key](https://docs.adyen.com/development-resources/client-side-authentication#get-your-client-key).
   Required for Drop-in/Components to communicate with the Adyen API.
3. [Get your API key](https://docs.adyen.com/development-resources/how-to-get-the-api-key). Required
   to make requests from your server to the Adyen API.
4. [Set up your webhooks](https://docs.adyen.com/development-resources/webhooks/) to get the payment
   outcome.

## Requirements:

* [Checkout API v71](https://docs.adyen.com/api-explorer/Checkout/71/overview) or later.
* Get familiar with defining the right [returnUrl](/doc/RETURN_URL.md).

#### Android

* [Android 5.0](https://www.android.com/versions/lollipop-5-0/) (API 21) or later.
* [Kotlin 1.8.22](https://kotlinlang.org/docs/releases.html) or later.
* [AGP 8.1](https://developer.android.com/build/releases/gradle-plugin) or later with Gradle 8.
* Requires the usage of a `FlutterFragmentActivity` instead of the default `FlutterActivity` in the
  MainActivity of
  your [native Android](https://github.com/Adyen/adyen-flutter/blob/main/example/android/app/src/main/kotlin/com/adyen/checkout/flutter/example/MainActivity.kt)
  layer.

#### iOS

* [iOS 12](https://support.apple.com/en-us/118387) or later.
* Add the return URL handler to your AppDelegate in
  your [native iOS](https://github.com/Adyen/adyen-flutter/blob/5301abab34773e820c4fd38be54d3bf4bb247fd6/example/ios/Runner/AppDelegate.swift#L18)
  layer.
* Add a
  custom [URL scheme](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
  that matches the returnUrl you use.

> [!IMPORTANT]
> For the standalone Component integration, we recommend using Flutter v3.29.2 or higher. Due
> to [this](https://github.com/flutter/flutter/issues/160854)
> Flutter issue, some Android 10 devices might experience a degraded performance when using a lower
> Flutter version.

## Integration

Depending on the [server-side flow](https://docs.adyen.com/online-payments/build-your-integration/)
you use, please follow the corresponding integration guide in our documentation.

### Sessions flow

* [Drop-in integration guide with Sessions flow](https://docs.adyen.com/online-payments/build-your-integration/sessions-flow/?platform=Flutter&integration=Drop-in)
* [Components integration guide with Sessions flow](https://docs.adyen.com/online-payments/build-your-integration/sessions-flow/?platform=Flutter&integration=Components)

### Advanced flow

* [Drop-in integration guide with Advanced flow](https://docs.adyen.com/online-payments/build-your-integration/advanced-flow/?platform=Flutter&integration=Drop-in)
* [Components integration guide with Advanced flow](https://docs.adyen.com/online-payments/build-your-integration/advanced-flow/?platform=Flutter&integration=Components)

### API only

* [API only integration guide](https://docs.adyen.com/payment-methods/cards/custom-card-integration/?tab=flutter_5)

## Customization & Localization

You can customize the styling of the user interface and change the wording if required. Follow the
guides for each platform:

* [UI customization](/doc/CUSTOMIZATION.md)
* [Localization](/doc/LOCALIZATION.md)

## Support

If you have a feature request, or spotted a bug or a technical problem, feel free to create a GitHub
issue. For other questions, please contact our Support Team
via [Customer Area](https://ca-live.adyen.com/ca/ca/contactUs/support.shtml) or via email:
support@adyen.com

## See also

* [Adyen Checkout API](https://docs.adyen.com/api-explorer/Checkout/latest/overview)
* [Adyen online payments documentation](https://docs.adyen.com/online-payments/)

## License

MIT license. For more information, see the LICENSE file.

