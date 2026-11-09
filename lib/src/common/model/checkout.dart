import 'checkout_callbacks.dart';
import 'payment_method.dart';
import 'stored_payment_method.dart';
import '../../checkout_runtime.dart';

class Checkout {
  final String id;
  final List<PaymentMethod> paymentMethods;
  final List<StoredPaymentMethod> storedPaymentMethods;
  final CheckoutCallbacks callbacks;
  final CheckoutRuntime _runtime;
  bool _disposed = false;

  Checkout._({
    required this.id,
    required List<PaymentMethod> paymentMethods,
    required List<StoredPaymentMethod> storedPaymentMethods,
    required this.callbacks,
    required CheckoutRuntime runtime,
  })  : paymentMethods = List<PaymentMethod>.unmodifiable(paymentMethods),
        storedPaymentMethods =
            List<StoredPaymentMethod>.unmodifiable(storedPaymentMethods),
        _runtime = runtime;

  bool get isDisposed => _disposed;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _runtime.disposeCheckout(id);
  }

  /// Presents Drop-in for this checkout.
  ///
  /// The returned future completes once Drop-in is presented. Payment results
  /// are delivered through [callbacks]: [CheckoutCallbacks.onComplete]
  /// on completion and [CheckoutCallbacks.onFailure] on failure. When
  /// the shopper dismisses Drop-in, [CheckoutCallbacks.onFailure] is
  /// invoked with [CheckoutError.cancellationCode].
  Future<void> startDropIn() => _runtime.startDropIn(id);
}

Checkout createCheckout({
  required String id,
  required List<PaymentMethod> paymentMethods,
  required List<StoredPaymentMethod> storedPaymentMethods,
  required CheckoutCallbacks callbacks,
  required CheckoutRuntime runtime,
}) =>
    Checkout._(
      id: id,
      paymentMethods: paymentMethods,
      storedPaymentMethods: storedPaymentMethods,
      callbacks: callbacks,
      runtime: runtime,
    );

CheckoutRuntime checkoutRuntimeOf(Checkout checkout) => checkout._runtime;

void markCheckoutDisposed(Checkout checkout) {
  checkout._disposed = true;
}
