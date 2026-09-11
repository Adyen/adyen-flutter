import 'checkout_callbacks.dart';
import 'payment_method.dart';
import 'stored_payment_method.dart';
import '../../checkout_runtime.dart';

abstract class CheckoutFlow {
  final String id;
  final List<PaymentMethod> paymentMethods;
  final List<StoredPaymentMethod> storedPaymentMethods;
  final CheckoutRuntime _runtime;
  bool _disposed = false;

  CheckoutFlow._({
    required this.id,
    required List<PaymentMethod> paymentMethods,
    required List<StoredPaymentMethod> storedPaymentMethods,
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
}

class SessionCheckout extends CheckoutFlow {
  final SessionCheckoutCallbacks callbacks;

  SessionCheckout._({
    required super.id,
    required super.paymentMethods,
    required super.storedPaymentMethods,
    required super.runtime,
    required this.callbacks,
  }) : super._();
}

class AdvancedCheckout extends CheckoutFlow {
  final AdvancedCheckoutCallbacks callbacks;

  AdvancedCheckout._({
    required super.id,
    required super.paymentMethods,
    required super.storedPaymentMethods,
    required super.runtime,
    required this.callbacks,
  }) : super._();
}

SessionCheckout createSessionCheckout({
  required String id,
  required List<PaymentMethod> paymentMethods,
  required List<StoredPaymentMethod> storedPaymentMethods,
  required SessionCheckoutCallbacks callbacks,
  required CheckoutRuntime runtime,
}) =>
    SessionCheckout._(
      id: id,
      paymentMethods: paymentMethods,
      storedPaymentMethods: storedPaymentMethods,
      callbacks: callbacks,
      runtime: runtime,
    );

AdvancedCheckout createAdvancedCheckout({
  required String id,
  required List<PaymentMethod> paymentMethods,
  required List<StoredPaymentMethod> storedPaymentMethods,
  required AdvancedCheckoutCallbacks callbacks,
  required CheckoutRuntime runtime,
}) =>
    AdvancedCheckout._(
      id: id,
      paymentMethods: paymentMethods,
      storedPaymentMethods: storedPaymentMethods,
      callbacks: callbacks,
      runtime: runtime,
    );

CheckoutRuntime checkoutRuntimeOf(CheckoutFlow flow) => flow._runtime;

void markFlowDisposed(CheckoutFlow flow) {
  flow._disposed = true;
}
