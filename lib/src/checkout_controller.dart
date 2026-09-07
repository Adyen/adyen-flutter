import 'package:flutter/foundation.dart';

class CheckoutController extends ChangeNotifier {
  bool _isReady = false;
  bool? _requiresUserInteraction;
  Future<void> Function()? _submit;
  bool _attached = false;
  bool _disposed = false;

  bool get isReady => _isReady;

  bool? get requiresUserInteraction => _requiresUserInteraction;

  bool get isDisposed => _disposed;

  Future<void> submit() async {
    if (_disposed) {
      throw StateError('Cannot submit using a disposed CheckoutController.');
    }
    if (!_attached) {
      throw StateError('CheckoutController is not attached to a component.');
    }
    if (!_isReady) {
      throw StateError('Cannot submit before the component is ready.');
    }
    final submit = _submit;
    if (submit == null) {
      throw StateError('Component submission is not available.');
    }
    await submit();
  }

  void _attach(Future<void> Function() submit) {
    if (_disposed) {
      throw StateError('Cannot attach a disposed CheckoutController.');
    }
    if (_attached) {
      throw StateError(
          'CheckoutController is already attached to a component.');
    }
    _attached = true;
    _submit = submit;
  }

  void _markReady(bool requiresUserInteraction) {
    if (_disposed || !_attached) return;
    if (_isReady && _requiresUserInteraction == requiresUserInteraction) return;
    _isReady = true;
    _requiresUserInteraction = requiresUserInteraction;
    notifyListeners();
  }

  void _detach() {
    if (_disposed) return;
    _attached = false;
    _submit = null;
    _isReady = false;
    _requiresUserInteraction = null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _attached = false;
    _submit = null;
    _isReady = false;
    _requiresUserInteraction = null;
    super.dispose();
  }
}

void attachCheckoutController(
  CheckoutController controller,
  Future<void> Function() submit,
) {
  controller._attach(submit);
}

void markCheckoutControllerReady(
  CheckoutController controller,
  bool requiresUserInteraction,
) {
  controller._markReady(requiresUserInteraction);
}

void detachCheckoutController(CheckoutController controller) {
  controller._detach();
}
