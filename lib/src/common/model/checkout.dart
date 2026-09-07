import 'checkout_callbacks.dart';
import 'payment_method.dart';
import 'stored_payment_method.dart';
import '../../checkout_coordinator.dart';

abstract class CheckoutFlow {
  final String id;
  final List<PaymentMethod> paymentMethods;
  final List<StoredPaymentMethod> storedPaymentMethods;
  final CheckoutCoordinator _coordinator;
  bool _disposed = false;

  CheckoutFlow._({
    required this.id,
    required List<PaymentMethod> paymentMethods,
    required List<StoredPaymentMethod> storedPaymentMethods,
    required CheckoutCoordinator coordinator,
  })  : paymentMethods = List<PaymentMethod>.unmodifiable(paymentMethods),
        storedPaymentMethods =
            List<StoredPaymentMethod>.unmodifiable(storedPaymentMethods),
        _coordinator = coordinator;

  bool get isDisposed => _disposed;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _coordinator.disposeCheckout(id);
  }
}

class SessionCheckout extends CheckoutFlow {
  final SessionCheckoutCallbacks callbacks;

  SessionCheckout._({
    required super.id,
    required super.paymentMethods,
    required super.storedPaymentMethods,
    required super.coordinator,
    required this.callbacks,
  }) : super._();
}

class AdvancedCheckout extends CheckoutFlow {
  final AdvancedCheckoutCallbacks callbacks;

  AdvancedCheckout._({
    required super.id,
    required super.paymentMethods,
    required super.storedPaymentMethods,
    required super.coordinator,
    required this.callbacks,
  }) : super._();
}

SessionCheckout createSessionCheckout({
  required String id,
  required List<PaymentMethod> paymentMethods,
  required List<StoredPaymentMethod> storedPaymentMethods,
  required SessionCheckoutCallbacks callbacks,
  required CheckoutCoordinator coordinator,
}) =>
    SessionCheckout._(
      id: id,
      paymentMethods: paymentMethods,
      storedPaymentMethods: storedPaymentMethods,
      callbacks: callbacks,
      coordinator: coordinator,
    );

AdvancedCheckout createAdvancedCheckout({
  required String id,
  required List<PaymentMethod> paymentMethods,
  required List<StoredPaymentMethod> storedPaymentMethods,
  required AdvancedCheckoutCallbacks callbacks,
  required CheckoutCoordinator coordinator,
}) =>
    AdvancedCheckout._(
      id: id,
      paymentMethods: paymentMethods,
      storedPaymentMethods: storedPaymentMethods,
      callbacks: callbacks,
      coordinator: coordinator,
    );

void markFlowDisposed(CheckoutFlow flow) {
  flow._disposed = true;
}
