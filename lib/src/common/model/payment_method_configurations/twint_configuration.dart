class TwintConfiguration {
  final String iosCallbackAppScheme;
  final bool showStorePaymentField;

  const TwintConfiguration({
    this.iosCallbackAppScheme = "",
    this.showStorePaymentField = true,
  });

  @override
  String toString() {
    return 'TwintConfiguration('
        'callbackAppScheme: $iosCallbackAppScheme, '
        'showStorePaymentField: $showStorePaymentField)';
  }
}
