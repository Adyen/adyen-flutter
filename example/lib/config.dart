class Config {
  /*
  Please add a json file with the name "secrets.json" that contains the following fields to the root of the example project:

  Example json
  {
    "CLIENT_KEY" : "YOUR_CLIENT_KEY",
    "X_API_KEY" : "YOUR X_API_KEY"
  }
  */
  static const String clientKey = String.fromEnvironment('CLIENT_KEY');
  static const String xApiKey = String.fromEnvironment('X_API_KEY');

  //Environment constants
  static const String merchantAccount = "TestMerchantCheckout";
  static const String countryCode = "NL";
  static const String shopperReference = "Test reference";
}
