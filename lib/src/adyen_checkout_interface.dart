abstract class AdyenCheckoutInterface {
  Future<String> getReturnUrl();

  void enableConsoleLogging({required bool enabled});
}
