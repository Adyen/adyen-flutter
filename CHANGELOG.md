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
