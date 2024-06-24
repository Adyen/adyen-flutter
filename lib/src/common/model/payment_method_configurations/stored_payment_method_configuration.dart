class StoredPaymentMethodConfiguration {
  final bool? showPreselectedStoredPaymentMethod;
  final bool? isRemoveStoredPaymentMethodEnabled;
  final Future<bool> Function(String)? deleteStoredPaymentMethodCallback;

  StoredPaymentMethodConfiguration({
    this.showPreselectedStoredPaymentMethod,
    this.isRemoveStoredPaymentMethodEnabled,
    this.deleteStoredPaymentMethodCallback,
  });
}
