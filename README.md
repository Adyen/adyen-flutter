![flutter-banner](https://github.com/Adyen/adyen-flutter/assets/13377878/6ca10143-9f75-43c6-bf6e-99011b09dd64)
# Adyen Flutter (alpha)

> [!IMPORTANT]
> **This package is an alpha version. Breaking changes might be included in later versions.**

The Adyen Flutter package provides you with the building blocks to create a seamless checkout experience for your Android and iOS Flutter app.

You can integrate in two ways:

- Drop-in: An out-of-the-box solution that includes all available payment methods for shoppers to choose. This wrapper for the native iOS and Android Adyen Drop-in is the quickest way to accept payments in your app.
- Card component: A dedicated card widget for shoppers to pay with a card. This is a wrapper for the native iOS and Android Adyen card Components.
  ![preview](https://github.com/Adyen/adyen-android/assets/9079915/e6e18a07-b30f-41f0-b7ef-701b20e2e339)

## Before you begin

1. Get an [Adyen test account](https://www.adyen.com/signup).  
2. [Get your Client key](https://docs.adyen.com/development-resources/client-side-authentication#get-your-client-key). Your client app does not communicate with the Adyen API directly.
3. [Get your API key](https://docs.adyen.com/development-resources/how-to-get-the-api-key). You need the API key to make requests from your server .
4. [Set up your webhooks](https://docs.adyen.com/development-resources/webhooks/) to get the payment outcome.


##  Install the package

### Add the package:

Run the following Flutter command:
```
$ flutter pub add adyen_checkout
```
This will add line like this to your package's `pubspec.yaml` file and runs an implicit `flutter pub get`:
```yaml
dependencies:
  adyen_checkout: ^0.0.1
```
Alternatively, your editor might support flutter pub get. Check the docs for your editor to learn more.

### Use the package
Import the Adyen package to your Dart code:

```dart
import 'package:adyen_checkout/adyen_checkout.dart';
```
<br/>

### Android integration
This package supports Android 5.0 or later.

#### For Drop-in and card Component:

Adjust your activity to inherit from `FlutterFragmentActivity`:
  ```kotlin
  import io.flutter.embedding.android.FlutterFragmentActivity

  class MainActivity: FlutterFragmentActivity() {
      // ...
  }
  ```
#### For card Component only:

Declare the intent filter in your `AndroidManifest.xml` file:
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

### iOS integration
This package supports iOS 12 or later.

Add the return URL handler to your `AppDelegate.swift` file:

```swift
override func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        	RedirectComponent.applicationDidOpen(from: url)
       	 return true
}
```
In your app, add a [custom URL Scheme](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app) that matches the return URL. </br>

#### For Drop-in only

Voucher payment methods require a photo library usage description. Add them to the `Info.plist` file.



##  How it works


You can use Adyen Flutter with either of our [server-side flows](https://docs.adyen.com/online-payments/build-your-integration/additional-use-cases/):
- Sessions flow
- Advanced flow
  
You must use [Checkout API](https://docs.adyen.com/api-explorer/Checkout/latest/overview) v71 or later.
### Drop-in with Sessions flow:

1.  From your server, make a [`/sessions`](https://docs.adyen.com/api-explorer/Checkout/71/post/sessions) request.

The response contains:<br>
- `sessionData`: the payment session data you need to pass to your front end.<br>
- `id`: a unique identifier for the session data.<br>
- The request body.

Put these into a `sessionResponse` object and pass it to your client app.


2. Create the `DropInConfiguration`.
```dart
final DropInConfiguration dropInConfiguration = DropInConfiguration(
  environment: Environment.test,
  clientKey: Config.clientKey,
  countryCode: Config.countryCode,
  shopperLocale: Config.shopperLocale,
  amount: Config.amount,
);
```
The `DropInConfiguration` also supports optional payment method configurations.

3. Call the `create` method, passing the required properties:
```dart 
   final SessionCheckout sessionCheckout = await AdyenCheckout.session.create(
     sessionId: sessionResponse.id,
     sessionData: sessionResponse.sessionData,
     configuration: dropInConfiguration,
   );
```
4. Call `startDropin` to start the Drop-in UI and wait for the session payment result. Drop-in handles the payment flow: 
```dart 
final PaymentResult paymentResult =  await AdyenCheckout.session.startDropIn(
  dropInConfiguration: dropInConfiguration,
  checkout: sessionCheckout,
);
```

5. Handle the payment result.
   1. Inform the shopper.
   Use the [`resultCode`](https://docs.adyen.com/online-payments/build-your-integration/payment-result-codes/) from the API response to show your shopper the current payment status.
   2. Update your order management system.
   You get the final payment status in an **AUTHORISATION** webhook. Use the `merchantReference` from the webhook to match it to your order reference.
   For a successful payment, the event contains `success`: **true**.


### Drop-in with Advanced flow:

1. From your server, make a [`/paymentMethods`](https://docs.adyen.com/api-explorer/Checkout/71/post/paymentMethods) request.
2. Create the `DropInConfiguration`.
```dart
final DropInConfiguration dropInConfiguration = DropInConfiguration(
  environment: Environment.test,
  clientKey: Config.clientKey,
  countryCode: Config.countryCode,
  shopperLocale: Config.shopperLocale,
  amount: Config.amount,
);
```
The `DropInConfiguration` also supports optional payment method configurations.

3. Create an `AdvancedCheckout` object and provide two callbacks<br>
   - `postPayments`: from your server, make a [`/payments`](https://docs.adyen.com/api-explorer/Checkout/latest/post/payments) request.<br>
   - `postPaymentsDetails`: from your server, make a [/payments/details](https://docs.adyen.com/api-explorer/Checkout/71/post/payments/details)
```dart
final AdvancedCheckout advancedCheckout = AdvancedCheckout(
  postPayments: widget.repository.postPayments,
  postPaymentsDetails: widget.repository.postPaymentsDetails,
);
```

4. Start the Drop-in UI and wait for the payment result. Drop-in handles the payment flow:
```dart 
final paymentResult = await AdyenCheckout.advanced.startDropIn(
  dropInConfiguration: dropInConfiguration,
  paymentMethodsResponse: paymentMethodsResponse,
  checkout: advancedCheckout,
);
```

5. Handle the payment result.
Inform the shopper.
Use the [`resultCode`](https://docs.adyen.com/online-payments/build-your-integration/payment-result-codes/) from the API response to show your shopper the current payment status.
Update your order management system.
You get the final payment status in an **AUTHORISATION** webhook. Use the `merchantReference` from the webhook to match it to your order reference.
For a successful payment, the event contains `success`: **true**.

<br>

### Card Component with Sessions flow:
1. From your server, make a [`sessions`](https://docs.adyen.com/api-explorer/Checkout/71/post/sessions) request.The response contains:<br>
- `sessionData`: the payment session data you need to pass to your front end.<br>
- `id`: a unique identifier for the session data.<br>
- The request body.

Put these into a `sessionResponse` object and pass it to your client app.

2. Create the `CardComponentConfiguration`.
```dart
final CardComponentConfiguration cardComponentConfiguration = CardComponentConfiguration(
  environment: Config.environment,
  clientKey: Config.clientKey,
  countryCode: Config.countryCode,
  amount: Config.amount,
  shopperLocale: Config.shopperLocale,
);
```
3. Call the `create` method, passing the required properties:
```dart
final sessionCheckout = await AdyenCheckout.session.create(
  sessionId: sessionResponse.id,
  sessionData: sessionResponse.sessionData,
  configuration: cardComponentConfiguration,
);
```
4. Get the card payment method to use from the `sessionCheckout` object.
5. Create the card component widget:
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
### Card Component with Advanced flow:

1. From your server, make a [`/paymentMethods`](https://docs.adyen.com/api-explorer/Checkout/71/post/paymentMethods) request.

2. Get the card payment method to use the payment methods list in the response.
3. Create the `CardComponentConfiguration`.
```dart
final CardComponentConfiguration cardComponentConfiguration = CardComponentConfiguration(
  environment: Config.environment,
  clientKey: Config.clientKey,
  countryCode: Config.countryCode,
  amount: Config.amount,
  shopperLocale: Config.shopperLocale,
);
```
4. Create an `AdvancedCheckout` object and provide two callbacks:<br>
- `postPayments`: from your server, make a [`/payments`](https://docs.adyen.com/api-explorer/Checkout/latest/post/payments) request. <br>
- `postPaymentsDetails: from your server, make a [`/payments/details](https://docs.adyen.com/api-explorer/Checkout/71/post/payments/details
```dart
final AdvancedCheckout advancedCheckout = AdvancedCheckout(
  postPayments: repository.postPayments,
  postPaymentsDetails: repository.postPaymentsDetails,
);
```
5. Create the card component widget:
```dart
AdyenCardComponent(
  configuration: cardComponentConfiguration,
  paymentMethod: paymentMethod,
  checkout: advancedCheckout,
  onPaymentResult: (paymentResult) async {
    // handle paymentResult
  },
);
``` 


## Support

If you have a feature request, or spot a bug or a technical problem, [create an issue](https://github.com/Adyen/adyen-flutter/issues).

For other questions, [contact our support team](https://www.adyen.help/hc/en-us/requests/new).
## Contributing

We merge every pull request into the `main` branch. We aim to keep `main` in good shape, which allows us to release a new version whenever we need to.

We strongly encourage you to provide feedback or  contribute to our repository. Have  a look at our [contribution guidelines](https://github.com/Adyen/.github/blob/master/CONTRIBUTING.md) to find out how to raise a pull request.

## License

This repository is available under the [MIT license](LICENSE).
