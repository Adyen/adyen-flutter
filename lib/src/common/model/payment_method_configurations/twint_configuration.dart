class TwintConfiguration {
  final String iosCallbackAppScheme;
  final bool showStorePaymentField;

  const TwintConfiguration({
    this.iosCallbackAppScheme = "",
    this.showStorePaymentField = false,
  });

  @override
  String toString() {
    return 'TwintConfiguration('
        'callbackAppScheme: $iosCallbackAppScheme, '
        'showStorePaymentField: $showStorePaymentField)';
  }
}
