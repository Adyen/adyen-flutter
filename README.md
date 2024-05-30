![flutter](https://github.com/Adyen/adyen-flutter/assets/13377878/4c8d6cca-24bf-4892-9dc2-a34a8af5a575)
# Adyen Flutter (beta)

> [!IMPORTANT]
> **This package is a beta version. Breaking changes might be included in later versions.**

The Adyen Flutter package provides you with the building blocks to create a seamless checkout experience for your Android and iOS Flutter app.

You can integrate in two ways:

- Drop-in: An out-of-the-box solution that includes all available payment methods for shoppers to choose. This wrapper for the native iOS and Android Adyen Drop-in is the quickest way to accept payments in your app.
- Components:
  - Card Component: A card widget for shoppers to pay with a card. The Card Component also supports stored cards.
  - Google Pay Component: A widget that renders a Google Pay button.
  - Apple Pay Component: A widget that renders an Apple Pay button.  
  - Instant Component: A way to support payment methods that do not require additional input fields (PayPal, Klarna, etc.).
  

|                                                             Android                                                              |                                                                iOS                                                                |
|:--------------------------------------------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------------------------------------------:|
| <img align="top" src="https://github.com/Adyen/adyen-android/assets/9079915/e6e18a07-b30f-41f0-b7ef-701b20e2e339" width="450" /> | <img align="top" src="https://github.com/Adyen/adyen-flutter/assets/13377878/05af212a-8141-4f8d-ad9d-f6506a7bade9" width="450" /> |

## Before you begin

1. Get an [Adyen test account](https://www.adyen.com/signup).  
2. [Get your Client key](https://docs.adyen.com/development-resources/client-side-authentication#get-your-client-key). Your client app does not communicate with the Adyen API directly.
3. [Get your API key](https://docs.adyen.com/development-resources/how-to-get-the-api-key). You need the API key to make requests from your server .
4. [Set up your webhooks](https://docs.adyen.com/development-resources/webhooks/) to get the payment outcome.


## Install the package

### Android integration
This package supports Android 5.0 or later.


Adjust your activity to inherit from `FlutterFragmentActivity`:
  ```kotlin
  import io.flutter.embedding.android.FlutterFragmentActivity

  class MainActivity: FlutterFragmentActivity() {
      // ...
  }
  ```
#### For Components
Declare the intent filter in your `AndroidManifest.xml` file for every component you are using:
  ```xml
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:host="YOUR_APPLICATION_ID e.g. com.adyen.checkout.flutter.example"
            android:path="YOUR_CUSTOM_PATH e.g. /card or /googlePay"
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


#### For Apple Pay (Drop-in or Component)
In your Runner target, add Apple Pay as a capability and enter your merchant id. Follow the steps on the enable [Apple Pay page](https://docs.adyen.com/payment-methods/apple-pay/enable-apple-pay/). 


##  How it works

You can use Adyen Flutter with either of our [server-side flows](https://docs.adyen.com/online-payments/build-your-integration/additional-use-cases/):
- Sessions flow
- Advanced flow
  
You must use [Checkout API](https://docs.adyen.com/api-explorer/Checkout/latest/overview) v71 or later.
<br>

### Drop-in with Sessions flow

1.  From your backend, make a [`/sessions`](https://docs.adyen.com/api-explorer/Checkout/71/post/sessions) request.

The response contains:<br>
- `sessionData`: the payment session data you need to pass to your front end.<br>
- `id`: a unique identifier for the session data.<br>

2. Pass these values to your app.


3. Create the `DropInConfiguration`. 
```dart
final DropInConfiguration dropInConfiguration = DropInConfiguration(
  // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test,
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  shopperLocale: SHOPPER_LOCALE,
  amount: AMOUNT,
);
```
The `DropInConfiguration` also supports optional payment method configurations.

4. Call the `create` method, passing the required properties:
```dart 
   final SessionCheckout sessionCheckout = await AdyenCheckout.session.create(
     sessionId: sessionResponse.id,
     sessionData: sessionResponse.sessionData,
     configuration: dropInConfiguration,
   );
```
5. Call `startDropin` to start the Drop-in UI and wait for the session payment result. Drop-in handles the payment flow: 
```dart 
final PaymentResult paymentResult =  await AdyenCheckout.session.startDropIn(
  dropInConfiguration: dropInConfiguration,
  checkout: sessionCheckout,
);
```

6. Handle the payment result.
   1. Inform the shopper.
   Use the [`resultCode`](https://docs.adyen.com/online-payments/build-your-integration/payment-result-codes/) from the API response to show your shopper the current payment status.
   2. Update your order management system.
   You get the final payment status in an **AUTHORISATION** webhook. Use the `merchantReference` from the webhook to match it to your order reference.
   For a successful payment, the event contains `success`: **true**.
<br>

### Drop-in with Advanced flow

1. From your backend, make a [`/paymentMethods`](https://docs.adyen.com/api-explorer/Checkout/71/post/paymentMethods) request.
2. Create the `DropInConfiguration`. In this object, you can also add optional payment method configurations.
```dart
final DropInConfiguration dropInConfiguration = DropInConfiguration(
   // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test,
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  shopperLocale: SHOPPER_LOCALE,
  amount: AMOUNT,
);
```

3. Create an `AdvancedCheckout` and provide two callbacks:
- `onSubmit`: from your backend, make a [`/payments`](https://docs.adyen.com/api-explorer/Checkout/latest/post/payments) request. The callback returns two parameters:
  - `data`: payment data that needs to be forwarded.
  - `extra`: extra information (e.g. shipping address) in case it is specified for the payment method configuration. Can be null if not needed.
- `onAdditionalDetails`: from your server, make a [`/payments/details`](https://docs.adyen.com/api-explorer/Checkout/71/post/payments/details)
```dart
final AdvancedCheckout advancedCheckout = AdvancedCheckout(
  onSubmit: YOUR_ON_SUBMIT_CALL,
  onAdditionalDetails: YOUR_ON_ADDITIONAL_DETAILS_CALL,
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

### Card Component with Sessions flow
1. From your backend, make a [`sessions`](https://docs.adyen.com/api-explorer/Checkout/71/post/sessions) request. The response contains:
- `sessionData`: the payment session data.
- `id`: a unique identifier for the session data.

2. Pass these values to your app.

3. Create the `CardComponentConfiguration`.
```dart
final CardComponentConfiguration cardComponentConfiguration = CardComponentConfiguration(
  // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test,
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  shopperLocale: SHOPPER_LOCALE,
  amount: AMOUNT,
);
```
4. Call the `create` method, passing the required properties:
```dart
final sessionCheckout = await AdyenCheckout.session.create(
  sessionId: sessionResponse.id,
  sessionData: sessionResponse.sessionData,
  configuration: cardComponentConfiguration,
);
```
5. Get the card payment method to use from the `sessionCheckout` object.
6. Create the card component widget:
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
<br>

### Card Component with Advanced flow

1. From your server, make a [`/paymentMethods`](https://docs.adyen.com/api-explorer/Checkout/71/post/paymentMethods) request.
2. Get the card payment method from the payment methods list.
3. Create the `CardComponentConfiguration`.
```dart
final CardComponentConfiguration cardComponentConfiguration = CardComponentConfiguration(
  // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test,
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  shopperLocale: SHOPPER_LOCALE,
  amount: AMOUNT,
);
```
4. Create an `AdvancedCheckout` and provide two callbacks:
- `onSubmit`: from your backend, make a [`/payments`](https://docs.adyen.com/api-explorer/Checkout/latest/post/payments) request. The callback returns two parameters:
  - `data`: payment data that needs to be forwarded.
  - `extra`: Will be null because it is not supported for cards.
- `onAdditionalDetails`: from your backend, make a [`/payments/details`](https://docs.adyen.com/api-explorer/Checkout/71/post/payments/details)
```dart
final AdvancedCheckout advancedCheckout = AdvancedCheckout(
  onSubmit: YOUR_ON_SUBMIT_CALL,
  onAdditionalDetails: YOUR_ON_ADDITIONAL_DETAILS_CALL,
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
<br>

### Apple Pay Component with Sessions flow
1. From your backend, make a [`sessions`](https://docs.adyen.com/api-explorer/Checkout/71/post/sessions) request. The response contains:
- `sessionData`: the payment session data.
- `id`: a unique identifier for the session data.

2. Pass these values to your app.

3. In your Flutter app, create a `ApplePayComponentConfiguration` instance. It requires a `ApplePayConfiguration` which contains your merchant id and merchant name.

```dart
final ApplePayConfiguration applePayConfiguration = ApplePayConfiguration(
  merchantId: MERCHANT_ID,
  merchantName: MERCHANT_NAME,
);

final ApplePayComponentConfiguration applePayComponentConfiguration = ApplePayComponentConfiguration(
  // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  amount: AMOUNT,
  applePayConfiguration: applePayComponentConfiguration,
);
```
4. Create a `SessionCheckout` by calling the `AdyenCheckout.session.create()` while passing the required properties:
```dart
final sessionCheckout = await AdyenCheckout.session.create(
  sessionId: sessionResponse.id,
  sessionData: sessionResponse.sessionData,
  configuration: applePayComponentConfiguration,
);
```
5. Get the Apple Pay payment method from the `sessionCheckout` object.
6. Use the Apple Pay component widget:
```dart
AdyenApplePayComponent(
  configuration: applePayComponentConfiguration,
  paymentMethod: applePayPaymentMethod,
  checkout: sessionCheckout,
  style: ApplePayButtonStyle(width: 200, height: 48),
  onPaymentResult: (paymentResult) {
    //Handle the payment result
  },
),
``` 
<br>

### Apple Pay Component with Advanced flow

1. From your backend, make a [`/paymentMethods`](https://docs.adyen.com/api-explorer/Checkout/71/post/paymentMethods) request.
2. Get the Apple Pay payment method by filtering the payment methods list.
3. Create the `ApplePayComponentConfiguration`. It requires the `ApplePayConfiguration` which contains your merchant id and merchant name. You can also provide optional properties for an enhanced Apple Pay use case.

```dart
final ApplePayConfiguration applePayConfiguration = ApplePayConfiguration(
  merchantId: MERCHANT_ID,
  merchantName: MERCHANT_NAME,
);

final ApplePayComponentConfiguration applePayComponentConfiguration = ApplePayComponentConfiguration(
  // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  amount: AMOUNT,
  applePayConfiguration: applePayComponentConfiguration,
);
```
4. Create an `AdvancedCheckout` and provide two callbacks:
- `onSubmit`: from your backend, make a [`/payments`](https://docs.adyen.com/api-explorer/Checkout/latest/post/payments) request. The callback returns two parameters:
  - `data`: payment data that needs to be forwarded.
  - `extra`: extra information (e.g. shipping address) in case it is specified in the Apple Pay configuration. Can be null if not needed.
- `onAdditionalDetails`: from your backend, make a [`/payments/details`](https://docs.adyen.com/api-explorer/Checkout/71/post/payments/details)
```dart
final AdvancedCheckout advancedCheckout = AdvancedCheckout(
  onSubmit: YOUR_ON_SUBMIT_CALL,
  onAdditionalDetails: YOUR_ON_ADDITIONAL_DETAILS_CALL,
);
```

5. Create the Apple Pay component widget:
```dart
AdyenApplePayComponent(
  configuration: applePayComponentConfiguration,
  paymentMethod: paymentMethod,
  checkout: advancedCheckout,
  style: ApplePayButtonStyle(width: 200, height: 48),
  onPaymentResult: (paymentResult) {
      //Handle the payment result
  },
),
``` 
<br>

### Google Pay Component with Sessions flow
1. From your backend, make a [`sessions`](https://docs.adyen.com/api-explorer/Checkout/71/post/sessions) request. The response contains:
- `sessionData`: the payment session data.
- `id`: a unique identifier for the session data.

2. Pass these values to your app.

3. In your Flutter app, create a `GooglePayComponentConfiguration` instance. It requires a `GooglePayConfiguration` which contains the Google Pay environment.

```dart
final GooglePayComponentConfiguration googlePayComponentConfiguration = GooglePayComponentConfiguration(
  // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test,
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  amount: AMOUNT,
  googlePayConfiguration: const GooglePayConfiguration(
    // Change the environment to live when you are ready to accept real payments.
    googlePayEnvironment: GooglePayEnvironment.test,
  ),
);
```
4. Create a `SessionCheckout` by calling the `AdyenCheckout.session.create()` while passing the required properties:
```dart
final sessionCheckout = await AdyenCheckout.session.create(
  sessionId: sessionResponse.id,
  sessionData: sessionResponse.sessionData,
  configuration: googlePayComponentConfiguration,
);
```
5. Get the Google Pay payment method from the `sessionCheckout` object.
6. Use the Google Pay component widget:
```dart
AdyenGooglePayComponent(
  configuration: googlePayComponentConfiguration,
  paymentMethod: paymentMethod,
  checkout: sessionCheckout,
  loadingIndicator: const CircularProgressIndicator(),
  onPaymentResult: (paymentResult) {
    //Handle the payment result
  },
),
``` 
<br>

### Google Pay Component with Advanced flow

1. From your backend, make a [`/paymentMethods`](https://docs.adyen.com/api-explorer/Checkout/71/post/paymentMethods) request.
2. Get the Google Pay payment method by filtering the payment methods list.
3. Create the `GooglePayComponentConfiguration`. It requires the `GooglePayConfiguration` which contains the Google Pay environment. You can also provide optional properties for an enhanced Google Pay use case.

```dart
 final GooglePayComponentConfiguration googlePayComponentConfiguration = GooglePayComponentConfiguration(
  // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test,
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  amount: AMOUNT,
  googlePayConfiguration: const GooglePayConfiguration(
    // Change the environment to live when you are ready to accept real payments.
    googlePayEnvironment: GooglePayEnvironment.test,
    shippingAddressRequired: true,
  ),
);
```
4. Create an `AdvancedCheckout` and provide two callbacks:
- `onSubmit`: from your backend, make a [`/payments`](https://docs.adyen.com/api-explorer/Checkout/latest/post/payments) request. The callback returns two parameters:
  - `data`: payment data that needs to be forwarded.
  - `extra`: extra information (e.g. shipping address) in case it is specified in the Google Pay configuration. Can be null if not needed.
- `onAdditionalDetails`: from your backend, make a [`/payments/details`](https://docs.adyen.com/api-explorer/Checkout/71/post/payments/details)
```dart
final AdvancedCheckout advancedCheckout = AdvancedCheckout(
  onSubmit: YOUR_ON_SUBMIT_CALL,
  onAdditionalDetails: YOUR_ON_ADDITIONAL_DETAILS_CALL,
);
```

5. Create the Google Pay component widget:
```dart
 AdyenGooglePayComponent(
  configuration: googlePayComponentConfiguration,
  paymentMethod: paymentMethod,
  checkout: advancedCheckout,
  style: GooglePayButtonStyle(width: 250, cornerRadius: 4),
  loadingIndicator: const CircularProgressIndicator(),
  onPaymentResult: (paymentResult) {
    //Handle the payment result
  },
),
``` 

<br>

### Instant Component with Sessions flow
1. From your backend, make a [`sessions`](https://docs.adyen.com/api-explorer/Checkout/71/post/sessions) request. The response contains:
- `sessionData`: the payment session data.
- `id`: a unique identifier for the session data.

2. Pass these values to your app.

3. In your Flutter app, create an `InstantComponentConfiguration`.

```dart
final InstantComponentConfiguration instantComponentConfiguration = InstantComponentConfiguration(
  // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test,
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  amount: AMOUNT,
);
```
4. Create a `SessionCheckout` by calling the `AdyenCheckout.session.create()` while passing the required properties:
```dart
final SessionCheckout sessionCheckout = await AdyenCheckout.session.create(
  sessionId: sessionResponse.id,
  sessionData: sessionResponse.sessionData,
  configuration: instantComponentConfiguration,
);
```
5. Get your required instant payment method by filtering the payment methods list provided by the `SessionCheckout`.
6. Use the instant component:
```dart
final PaymentResult paymentResult = await AdyenCheckout.session.startInstantComponent(
  configuration: instantComponentConfiguration,
  paymentMethod: paymentMethodResponse,
  checkout: sessionCheckout,
);
``` 

<br>

### Instant Component with Advanced flow

1. From your backend, make a [`/paymentMethods`](https://docs.adyen.com/api-explorer/Checkout/71/post/paymentMethods) request.
2. Get the instant payment method by filtering the payment methods list.
3. In your Flutter app, create an `InstantComponentConfiguration`.

```dart
final InstantComponentConfiguration instantComponentConfiguration = InstantComponentConfiguration(
  // Change the environment to live when you are ready to accept real payments.
  environment: Environment.test,
  clientKey: CLIENT_KEY,
  countryCode: COUNTRY_CODE,
  amount: AMOUNT,
);
```
4. Create an `AdvancedCheckout` and provide two callbacks:
- `onSubmit`: from your backend, make a [`/payments`](https://docs.adyen.com/api-explorer/Checkout/latest/post/payments) request. The callback returns two parameters:
  - `data`: payment data that needs to be forwarded.
  - `extra`: extra information if available (e.g. shipping address). Can be null if not needed.
- `onAdditionalDetails`: from your backend, make a [`/payments/details`](https://docs.adyen.com/api-explorer/Checkout/71/post/payments/details)
```dart
final AdvancedCheckout advancedCheckout = AdvancedCheckout(
  onSubmit: YOUR_ON_SUBMIT_CALL,
  onAdditionalDetails: YOUR_ON_ADDITIONAL_DETAILS_CALL,
);
```

5. Use the instant component:
```dart
final PaymentResult paymentResult = await AdyenCheckout.advanced.startInstantComponent(
  configuration: instantComponentConfiguration,
  paymentMethod: paymentMethodResponse,
  checkout: advancedCheckout,
);
```
<br>

### Multi Component setup

The SDK currently supports component combination in the advanced flow only. By using this flow, you can use the card component together with the Google Pay or Apple Pay component.
<br>

## UI Customization


### Android

Follow the Android SDK [customization docs](https://github.com/Adyen/adyen-android/blob/develop/docs/UI_CUSTOMIZATION.md).

### iOS

In **Xcode** create swift class `AdyenAppearance` extending protocol `AdyenComponentAppearanceProvider` or `AdyenDropInAppearanceProvider` depending of your integration.
SDK will use reflection to find the class with this exact name. Our example app contains a [demo implementation](https://github.com/Adyen/adyen-flutter/blob/main/example/ios/Runner/AppDelegate.swift#L22).

Drop-in:

```swift
import Adyen
import adyen_checkout

class AdyenAppearance: AdyenDropInAppearanceProvider {
  static func createDropInStyle() -> Adyen.DropInComponent.Style {
     # provide your custom style here
  }
}
```

Card Component: 

```swift
import Adyen
import adyen_checkout

class AdyenAppearance: AdyenComponentAppearanceProvider {
  static func createCardComponentStyle() -> Adyen.FormComponentStyle {
     # provide your custom style here
  }
}
```

## Support

If you have a feature request, or spot a bug or a technical problem, [create an issue](https://github.com/Adyen/adyen-flutter/issues).

For other questions, [contact our support team](https://www.adyen.help/hc/en-us/requests/new).
## Contributing

We merge every pull request into the `main` branch. We aim to keep `main` in good shape, which allows us to release a new version whenever we need to.

We strongly encourage you to provide feedback or  contribute to our repository. Have  a look at our [contribution guidelines](https://github.com/Adyen/.github/blob/master/CONTRIBUTING.md) to find out how to raise a pull request.

## License

This repository is available under the [MIT license](LICENSE).
