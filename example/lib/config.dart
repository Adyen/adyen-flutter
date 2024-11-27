import 'package:adyen_checkout/adyen_checkout.dart';

class Config {
  /*
  Your `CLIENT_KEY` and `X_API_KEY` are sensitive credentials that must be secure.

  Do not provide them in your live environment through constants, because this is not secure. Instead, provide them dynamically from your server-side.

  For testing the example app, create a `secrets.json` file that contains the following properties:
  {
    "CLIENT_KEY" : "YOUR_CLIENT_KEY",
    "X_API_KEY" : "YOUR X_API_KEY"
    "APPLE_PAY_MERCHANT_ID_KEY": "YOUR_APPLE_PAY_MERCHANT_ID_KEY"
  }
  */
  static const String clientKey = String.fromEnvironment('CLIENT_KEY');
  static const String xApiKey = String.fromEnvironment('X_API_KEY');
  static const String merchantId =
      String.fromEnvironment('APPLE_PAY_MERCHANT_ID_KEY');
  static const String publicKey = String.fromEnvironment('PUBLIC_KEY');

  //Environment constants
  static const String merchantAccount = "FlutterTEST";
  static const String merchantName = "Test Merchant";
  static const String countryCode = "NL";
  static const String shopperLocale = "en-US";
  static const String shopperReference = "Test reference";
  static const Environment environment = Environment.test;
  static const String baseUrl = "checkout-test.adyen.com";
  static const String apiVersion = "v71";
  static const String iOSReturnUrl = "adyencheckout://com.adyen.adyen_checkout_example";
  static const GooglePayEnvironment googlePayEnvironment =
      GooglePayEnvironment.test;

  //Example data
  static Amount amount = Amount(currency: "EUR", value: 11295);
}
