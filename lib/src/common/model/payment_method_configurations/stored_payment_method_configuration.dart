class StoredPaymentMethodConfiguration {
  final bool? showPreselectedStoredPaymentMethod;
  final bool? isRemoveStoredPaymentMethodEnabled;
  final Future<bool> Function(String)? deleteStoredPaymentMethodCallback;

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
