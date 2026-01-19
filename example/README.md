# Adyen Flutter Example App

This example app demonstrates how to integrate the Adyen Flutter SDK into your application, enabling
various payment methods through Adyen's platform.

## Prerequisites

Before running the example app, ensure you have:

1. **Flutter SDK** installed and properly configured
2. **Android Studio** (for Android development)
3. **Xcode** (for iOS development, macOS only)
4. **Android emulator** or physical device (for Android testing)
5. **iOS simulator** or physical device (for iOS testing)
6. **Adyen Account** with API credentials
    - Test account can be obtained from [Adyen's Customer Area](https://ca-test.adyen.com/)

## Configuration Setup

### Create secrets.json

For testing the example app, create a `secrets.json` file in the example app root directory with
your Adyen API credentials:

```json
{
  "CLIENT_KEY": "YOUR_CLIENT_KEY",
  "X_API_KEY": "YOUR_X_API_KEY",
  "APPLE_PAY_MERCHANT_ID_KEY": "YOUR_APPLE_PAY_MERCHANT_ID_KEY",
  "PUBLIC_KEY": "YOUR_PUBLIC_KEY"
}
```

### Configuration Details

| Key                         | Description                                                                             |
|-----------------------------|-----------------------------------------------------------------------------------------|
| `CLIENT_KEY`                | Client-side API key for authenticating with Adyen                                       |
| `X_API_KEY`                 | Server-side API key (for testing purposes only, should be on your server in production) |
| `APPLE_PAY_MERCHANT_ID_KEY` | Your Apple Pay merchant identifier (for iOS only)                                       |
| `PUBLIC_KEY`                | Adyen public key used for client-side encryption                                        |

> ⚠️ **Security Note**: In a production application, API keys should be stored securely on your
> server and never included in client-side code. This example uses client-side keys for demonstration
> purposes only.


The `config.dart` file uses the values from your `secrets.json` file through the
`String.fromEnvironment()` method. When you run the app with `--dart-define-from-file=secrets.json`,
Flutter makes these values available at compile time.

```dart
// Values loaded from secrets.json
static const String clientKey = String.fromEnvironment('CLIENT_KEY');
static const String xApiKey = String.fromEnvironment('X_API_KEY');
static const String merchantId = String.fromEnvironment('APPLE_PAY_MERCHANT_ID_KEY');
static const String publicKey = String.fromEnvironment('PUBLIC_KEY');
```

#### Alternative: Hardcoding Values

As an alternative for development purposes only, you can directly modify `config.dart` to hardcode
your values:

```dart
// Not recommended for production but useful for development
static const String clientKey = "your_client_key_here";
static const String xApiKey = "your_api_key_here";
static const String merchantId = "your_apple_pay_merchant_id";
static const String publicKey = "your_public_key";
```

> ⚠️ **Warning**: Do not commit hardcoded secrets to version control. The secrets.json file keeps
> sensitive credentials gitignored.

#### Other Configurable Values

The `config.dart` file also contains other configurable settings:

| Setting                | Description                      | Default Value                         |
|------------------------|----------------------------------|---------------------------------------|
| `merchantAccount`      | Your merchant account name       | "FlutterTEST"                         |
| `merchantName`         | Display name for your store      | "Test Merchant"                       |
| `countryCode`          | Country code for payment methods | "NL"                                  |
| `shopperLocale`        | Language and region preference   | "en-US"                               |
| `environment`          | Adyen environment (test or live) | Environment.test                      |
| `baseUrl`              | Adyen API base URL               | "checkout-test.adyen.com"             |
| `apiVersion`           | Adyen API version                | "v71"                                 |
| `iOSReturnUrl`         | URL scheme for iOS returns       | "com.mydomain.adyencheckout://"       |
| `googlePayEnvironment` | Google Pay environment           | GooglePayEnvironment.test             |
| `amount`               | Default payment amount           | Amount(currency: "EUR", value: 11295) |

You may need to adjust these values based on your specific implementation requirements.

## Running the Example App

### For Android

1. **Start an Android emulator** or connect a physical device
2. **Run the app** with the following command:

```bash
cd /path/to/adyen-flutter/example
flutter run -d android --dart-define-from-file=secrets.json
```

3. **For a specific device** if you have multiple connected:

```bash
flutter devices  # List available devices
flutter run -d [device-id] --dart-define-from-file=secrets.json
```

### For iOS

1. **Start an iOS simulator** or connect a physical device
2. **Run the app** with:

```bash
cd /path/to/adyen-flutter/example
flutter run -d ios --dart-define-from-file=secrets.json
```

3. **For a specific simulator**:

```bash
flutter run -d "iPhone 15 Pro" --dart-define-from-file=secrets.json
```
