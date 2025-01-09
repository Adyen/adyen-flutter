## 1.3.0

### New

- Added card validators (Card number validation, card expiry date validation, card security code validation). 

## 1.2.0

### New
- iDEAL is now available through the Instant Component.
- For Google Pay Component on Advanced flow, added loading bottom sheet.
- The `paymentSessionFinished` payment result now contains `sessionResult`.
- You can now also make partial payments in Drop-in if your integration uses the Advanced flow.
- Updated iOS Components/Drop-in version: [5.14.0](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=iOS+Components%2FDrop-in#releaseNote=2024-12-03-ios-componentsdrop-in-5.14.0).
- Updated Android Components/Drop-in version: [5.8.0](https://docs.adyen.com/online-payments/release-notes/?title%5B0%5D=Android+Components%2FDrop-in#releaseNote=2024-12-06-android-componentsdrop-in-5.8.0). Gradle v8 is now mandatory.

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
