
import 'package:adyen_checkout/adyen_checkout.dart';

class Config {
  /*
  Please add a json file with the name "secrets.json" that contains the following properties to the root of the example project:

  Example:
  {
    "CLIENT_KEY" : "YOUR_CLIENT_KEY",
    "X_API_KEY" : "YOUR X_API_KEY"
  }
  */
  static const String clientKey = String.fromEnvironment('CLIENT_KEY');
  static const String xApiKey = String.fromEnvironment('X_API_KEY');

  //Environment constants
  static const String merchantAccount = "TestMerchantCheckout";
  static const String merchantName = "Test Merchant";
  static const String countryCode = "NL";
  static const String shopperLocale = "nl_NL";
  static const String shopperReference = "Test reference";
  static const Environment environment = Environment.test;
  static const String baseUrl = "checkout-test.adyen.com";
  static const String apiVersion = "v70";
  static const String iOSReturnUrl = "flutter-ui-host://payments";

  //Example data
  static Amount amount = Amount(currency: "EUR", value: 2100);
}
