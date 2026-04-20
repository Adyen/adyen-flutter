class StoredPaymentMethodConfiguration {
  final bool? showPreselectedStoredPaymentMethod;
  final bool? isRemoveStoredPaymentMethodEnabled;
  final Future<bool> Function(String)? deleteStoredPaymentMethodCallback;

  /// Controls whether stored payment methods are shown in the Drop-in list.
  ///
  /// Defaults to `true`, which keeps the current behavior: stored payment
  /// methods associated with the provided `shopperReference` are displayed.
  ///
  /// Set to `false` to hide stored payment methods from the Drop-in UI
  /// without changing the `shopperReference` — useful when you still need
  /// to tokenize new payment methods in the same session but do not want
  /// to expose previously stored ones (e.g. a guest-like checkout where
  /// the stored tokens should not be selectable).
  ///
  /// This mirrors the Web Drop-in option
  /// `cardConfiguration.showStoredPaymentMethods`.
  final bool? showStoredPaymentMethods;

  StoredPaymentMethodConfiguration({
    this.showPreselectedStoredPaymentMethod,
    this.isRemoveStoredPaymentMethodEnabled,
    this.deleteStoredPaymentMethodCallback,
    this.showStoredPaymentMethods,
  });

  @override
  String toString() {
    return 'StoredPaymentMethodConfiguration('
        'showPreselectedStoredPaymentMethod: $showPreselectedStoredPaymentMethod, '
        'isRemoveStoredPaymentMethodEnabled: $isRemoveStoredPaymentMethodEnabled, '
        'deleteStoredPaymentMethodCallback: $deleteStoredPaymentMethodCallback, '
        'showStoredPaymentMethods: $showStoredPaymentMethods)';
  }
}
