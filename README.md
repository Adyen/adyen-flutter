![flutter-banner](https://github.com/Adyen/adyen-flutter/assets/13377878/6ca10143-9f75-43c6-bf6e-99011b09dd64)
# Adyen Flutter (alpha)

**This package is an alpha version. Please take into consideration that breaking changes could occur in future versions.**   

Adyen Flutter provides you with the building blocks to create a checkout experience for your shoppers, allowing them to pay using the payment method of their choice.
The building blocks support Android and iOS.

You can integrate in two ways:

- Drop-in: A wrapper for the native iOS and Android Adyen Drop-in - an all-in-one solution, the quickest way to accept payments in your app.
- Card component: A wrapper for the native iOS and Android Adyen card components - A dedicated card widget, allowing card payments in your app.

![preview](https://github.com/Adyen/adyen-android/assets/9079915/e6e18a07-b30f-41f0-b7ef-701b20e2e339)

## Prerequisites

For the integration into your app a [Client key](https://docs.adyen.com/development-resources/client-side-authentication#get-your-client-key) is required. Please be aware that you should not communicate with the Adyen API directly. Instead route the requests through your own backend. For that, you need an [Adyen account](https://www.adyen.com/signup) and an [API key](https://docs.adyen.com/development-resources/how-to-get-the-api-key).

## Installation

### Add package:

With Flutter:
```
$ flutter pub add adyen_checkout
```
This will add a line like this to your package's pubspec.yaml (and run an implicit flutter pub get):
```yaml
dependencies:
  adyen_checkout: ^0.0.1
```
Alternatively, your editor might support flutter pub get. Check the docs for your editor to learn more.

### Use package
Now in your Dart code, you can use:
```dart
import 'package:adyen_checkout/adyen_checkout.dart';
```
<br/>

### Android integration (SDK >= 21)

Adjust your activity to inherit from `FlutterFragmentActivity`: 
  ```kotlin
  import io.flutter.embedding.android.FlutterFragmentActivity

  class MainActivity: FlutterFragmentActivity() {
      // ...
  }
  ```

When using the **card component**, it is necessary to declare the intent filter within `AndroidManifest.xml`. 
  ```xml
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:host="YOUR_APPLICATION_ID e.g. com.adyen.checkout.flutter.example"
            android:path="YOUR_CUSTOM_PATH e.g. /card"
            android:scheme="adyencheckout" />
    </intent-filter>
  ```
<br/>

### iOS integration (SDK >= 12)

Add return URL handler to your `AppDelegate.swift`: 

```swift
override func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        RedirectComponent.applicationDidOpen(from: url)
        return true
}
```
Add [custom URL Scheme](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app) to your app that matches the return URL. </br>
When using a voucher payment method in **drop-in**, add a photo library usage description to the `Info.plist` file.  

## Usage

For general understanding of how the prebuilt UI of Adyen (Drop-in or components) work you can follow [our documentation](https://docs.adyen.com/online-payments/prebuilt-ui).
Adyen offers two ways of proceeding payments within your app. Either through a `session` or through the `advanced` mode. 

### Drop-in session: 

1. Fetch a session from your backend. 
2. Create the `DropInConfiguration`. 
3. Request a session by using the package: 
```dart
final SessionCheckout sessionCheckout = await AdyenCheckout.session.create(
    sessionId: sessionResponse.id,
    sessionData: sessionResponse.sessionData,
    configuration: dropInConfiguration,
);
```
4. Start the Drop-in UI and wait for the payment result: 
```dart 
final PaymentResult paymentResult =  await AdyenCheckout.session.startDropIn(
    dropInConfiguration: dropInConfiguration,
    checkout: sessionCheckout,
);
```
5. The payment flow is completed. Continue by handling the payment result. 


### Drop-in advanced:

1. Fetch payment methods from you backend. 
2. Create the `DropInConfiguration`. 
3. Create an `AdvancedCheckout` object. You must provide two callbacks (`postPayments` and `postPaymentsDetails`) bridging to your backend. These callbacks are being triggered during the payment process. 
4. Start the Drop-in UI and wait for the payment result: 
```dart 
final paymentResult = await AdyenCheckout.advanced.startDropIn(
    dropInConfiguration: dropInConfiguration,
    paymentMethodsResponse: paymentMethodsResponse,
    checkout: advancedCheckout,
);
```
5. The payment flow is completed. Continue by handling the payment result. 

<br>

### Card component session:
1. Fetch a session from your backend. 
2. Create the `CardComponentConfiguration`. 
3. Request a session by using the package: 
```dart
final sessionCheckout = await AdyenCheckout.session.create(
    sessionId: sessionResponse.id,
    sessionData: sessionResponse.sessionData,
    configuration: cardComponentConfiguration,
);
```
4. Extract the desired card payment method from the sessionCheckout.
5. Create card component widget: 
```dart
AdyenCardComponent(
    configuration: cardComponentConfiguration,
    paymentMethod: paymentMethod,
    checkout: sessionCheckout,
    onPaymentResult: (paymentResult) async {
        // handle paymentResult
    },
);
``` 

### Card component advanced:

1. Fetch payment methods from you backend. 
2. Extract the desired card payment method from the payment methods list.
3. Create the `CardComponentConfiguration`. 
4. Create an `AdvancedCheckout` object. You must provide two callbacks (`postPayments` and `postPaymentsDetails`) bridging to your backend. These callbacks are being triggered during the payment process. 
5. Create card component widget: 
```dart
AdyenCardComponent(
    configuration: cardComponentConfiguration,
    paymentMethod: paymentMethod,
    checkout: advancedCheckout,
    onPaymentResult: (event) async {
        // handle paymentResult
    },
);
``` 


## Support

If you have a feature request, or spotted a bug or a technical problem, [create an issue here](https://github.com/Adyen/adyen-flutter/issues).

For other questions, [contact our support team](https://www.adyen.help/hc/en-us/requests/new).

## Analytics and data tracking

Drop-in and Components integrations contain analytics and tracking features that are turned on by default. Find out more about [what we track and how you can control it](https://docs.adyen.com/online-payments/analytics-and-data-tracking). Analytics can be disabled by setting `AnalyticsOptions(enabled: false)` within the configuration object.

## Contributing

We merge every pull request into the `develop` branch. We aim to keep `develop` in good shape, which allows us to release a new version whenever we need to.

We strongly encourage you to provide feedback or by contributing to our repository. Find out more in our [contribution guidelines](https://github.com/Adyen/.github/blob/master/CONTRIBUTING.md)

## License

This repository is available under the [MIT license](LICENSE).