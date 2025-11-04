## 1.7.0

### New

- Pay by Bank is now supported as an Instant Component. Payment
  method [type](https://docs.adyen.com/payment-methods/payment-method-types): **paybybank**.
- Support for Swift Package Manager (SPM).

### Improved

- For Apple Pay Component: the instantiation of the widget is now more efficient.
- For the Instant Component: streamlined the implementation for Android by removing redundant code.
- For Components in general: the communication of platformView height now includes a type
  specification.

### Changed

- Dependency versions:
  | Name | Version |
  |---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
  | [iOS Drop-in/Components](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=iOS+Components%2FDrop-in#releaseNote=2025-11-04-ios-componentsdrop-in-5.21.0) |  5.21.0 |

## 1.6.0

### Improved

- Improved initialization of Google Pay Component.
- For the Apple Pay Component:
    - Now uses PassKit for its availability check instead of a temporary native Adyen Apple Pay
      Component.
    - Billing contact fields are now correctly mapped.
- On iOS with the Advanced flow: when an error occurs during a card payment, the loading spinner now
  stops automatically.

### Changed

- Dependency versions:
  | Name                                                                                                                                                                      | Version |
  |---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
  | [Android Drop-in/Components](https://docs.adyen.com/online-payments/release-notes/#releaseNote=2025-08-19-android-componentsdrop-in-5.14.0)                               | 5.14.0  |
  | [iOS Drop-in/Components](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=iOS+Components%2FDrop-in#releaseNote=2025-08-27-ios-componentsdrop-in-5.20.0) | 5.20.0  |

## 1.5.1

### New

- Android Components/Drop-in
  version: [5.13.0](https://docs.adyen.com/online-payments/release-notes/#releaseNote=2025-07-03-android-componentsdrop-in-5.13.0).

### Fixed

- For card payments on Android, the expiry date field now works correctly when the shopper leaves
  the app, and resumes it from the background. This fixes the known issue in v1.5.0.

## 1.5.0

### New

- Android Components/Drop-in
  version: [5.12.0](https://docs.adyen.com/online-payments/release-notes/#releaseNote=2025-06-06-android-componentsdrop-in-5.12.0).
- iOS Components/Drop-in
  version: [5.19.1](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=iOS+Components%2FDrop-in#releaseNote=2025-06-06-ios-componentsdrop-in-5.19.0)

### Improved

- Improved how the Apple pay bottom sheet closes when dismissing Drop-in.
- When the shopper enters the details for a co-badged card, the available brand options are now
  shown in a separate section in the payment form.

### Warning

For Android: We've identified an issue where the expiry date input field for card payment in Drop-in
and Component functions incorrectly when the app is resumed from the background. This has been
fixed in v1.5.1.

## 1.4.0

### New

- For Sessions and Advanced flows, added methods to dismiss Drop-in.
- For the card component and cards within Drop-in, added support for BIN lookup callbacks that will
  be called when the shopper enters their card details.
- Added a custom card Flutter widget to the example app using CSE and card validators.
- Android Components/Drop-in
  version: [5.10.0](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=Android+Components%2FDrop-in#releaseNote=2025-04-07-android-componentsdrop-in-5.10.0).
- iOS Components/Drop-in
  version: [5.17.0](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=iOS+Components%2FDrop-in#releaseNote=2025-04-08-ios-componentsdrop-in-5.17.0)

### Changed

- Minimum SDK version:
  Flutter [3.16.0](https://docs.flutter.dev/release/release-notes/release-notes-3.16.0)
  /Dart 3.2

### Improved

- For native 3D Secure 2, when a shopper cancels the payment during the payment flow, the
  `onAdditionalDetails` callback is now triggered. The payment flow no longer ends with
  CANCELLED_BY_USER. The `onAdditionalDetails` returns the details of the cancelled transaction.

## 1.3.0

### New

- For custom card with API only integration: added validators for the following.
    - Card number.
    - Card expiry date.
    - Card security code.

- iOS Components/Drop-in
  version: [5.15.0](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=iOS+Components%2FDrop-in#releaseNote=2025-01-07-ios-componentsdrop-in-5.15.0).

### Improved

- For card component, on Android 8 (API level 26) or earlier, the pay button no longer has
  ripple animations to prevent an animation crash.

## 1.2.0

### New

- iDEAL is now available through the Instant Component.
- For Google Pay Component on Advanced flow, added loading bottom sheet.
- The `paymentSessionFinished` payment result now contains `sessionResult`.
- You can now also make partial payments in Drop-in if your integration uses the Advanced flow.
- iOS Components/Drop-in
  version: [5.14.0](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=iOS+Components%2FDrop-in#releaseNote=2024-12-03-ios-componentsdrop-in-5.14.0).
- Android Components/Drop-in
  version: [5.8.0](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=Android+Components%2FDrop-in#releaseNote=2024-12-06-android-componentsdrop-in-5.8.0).
  Gradle v8 is now mandatory.

### Improved

- For card component, improved the dynamic viewport.

### Removed

- Removed the alert message that appeared when deleting a stored payment method fails.

## 1.1.0

* Added support for renaming payment methods in Drop-in.
* 3DS2 cancellations are now resolved as a PaymentCancelledByUser payment result.
* Improved configuration parsing for Google Pay component.
* Improved instantiation of Apple Pay component.

## 1.0.2

* Improved card component for large font and display sizes.
* Improved component bottom sheet behavior on Android.
* Migrated Android example to use Flutter Gradle plugins through the Plugin DSL.
* Updated iOS SDK to v5.11.0.

## 1.0.1

* Fixed resolving of view references for Android when using Flutter with Gradle's Plugin DSL.
* Excluded default androidx.lifecycle dependencies of the Android SDK to enable AGP 7 compatibility.
* Updated project readme.

## 1.0.0

* ⚠ **Breaking Change**: Cash app pay configuration now uses named parameters.
* ⚠ **Breaking Change**: Styling for iOS is now simplified by exposing AdyenAppearance for setting
  the style directly.
* Added standalone action handling for the API only integration flow.
* Improved rendering of components.
* The amount inside the different payment method configurations is now optional. Only for Apple Pay
  in combination with the advanced flow, the amount is still required.
* Added support for the iDEAL redirect flow.
* Updated iOS SDK to v5.9.0.
* Updated Android SDK to v5.6.0 and moved to Gradle v8.

## 0.1.0

* ⚠ **Breaking Change**: Changed ResultCode into an enum. Please adjust your usage of the
  PaymentResult (PaymentSessionFinished or PaymentAdvancedFinished).
* ⚠ **Breaking Change**: Changed the payment methods type from String to Map<String, dynamic> to
  support JSON data directly.
* ⚠ **Breaking Change**: Updated AdvancedCheckout class and removed deprecated implementation.
* Updated iOS SDK to v5.8.0.
* Updated Android SDK to v5.4.0.
* Added support for customizing Drop-in and Card Component.
* Added option to adjust Drop-in preselected payment method title.
* Added support for Instant Component.
* Added support for Client-Side Encryption (CSE).

## 0.0.3

* ⚠ Introduced the AdvancedCheckoutPreview as a replacement for the AdvancedCheckout. Please
  consider using it as we plan to replace the deprecated AdvancedCheckout in the first beta
  release.
* Added Google Pay Component.
* Added Apple Pay Component.
* Added support for optional configuration for Apple Pay and Google Pay (Drop-in and Components).
* Updated minimum supported SDK version to Flutter 3.10.6/Dart 3.0.6.

## 0.0.2

* Improved error handling by dismissing Drop-in in case an Apple Pay transaction fails.
* Updated iOS SDK to v5.6.0.
* Updated Android SDK to v5.2.0.
* Updated API integration of example app to v71.

## 0.0.1

* Initial alpha release containing following features:
    * Drop-in with session flow and advanced flow.
    * Card-component with session flow and advanced flow. 
