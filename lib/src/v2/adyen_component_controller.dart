import 'package:flutter/foundation.dart';

/// A controller for observing the readiness of an [AdyenComponent] and for
/// triggering a submission when the component does not render its own submit
/// button (e.g. iDEAL or PayPal).
///
/// The controller is optional. When it is omitted, the component behaves as
/// before: interactive components (Card, BLIK, Google Pay, Apple Pay) render
/// their own native controls. When a direct (no-input) payment method is used,
/// a controller must be supplied and the merchant is responsible for calling
/// [submit] from a custom button.
///
/// Payment completion still arrives through the [AdyenComponent.onPaymentResult]
/// callback; [submit] only dispatches the submission to the native SDK.
final class AdyenComponentController extends ChangeNotifier {
  bool _isReady = false;
  bool? _requiresUserInteraction;
  Future<void> Function()? _submit;
  bool _attached = false;
  bool _disposed = false;

  /// Whether the native component has finished creation and reported its
  /// readiness. Before this is `true`, [requiresUserInteraction] is `null` and
  /// [submit] cannot be called.
  bool get isReady => _isReady;

  /// `true` when the native component requires user input (e.g. Card), `false`
  /// when it can be submitted directly (e.g. iDEAL, PayPal), and `null` before
  /// the native component has finished creation.
  bool? get requiresUserInteraction => _requiresUserInteraction;

  /// Submits the component to the native SDK.
  ///
  /// This completes after the submission has been dispatched. The final payment
  /// result is delivered through [AdyenComponent.onPaymentResult].
  ///
  /// Throws a [StateError] when:
  /// - the controller has not been attached to a component,
  /// - the component has not yet reported readiness,
  /// - the controller has been detached or disposed.
  Future<void> submit() async {
    if (_disposed) {
      throw StateError(
        'Cannot submit using a disposed AdyenComponentController.',
      );
    }
    if (!_attached) {
      throw StateError(
        'AdyenComponentController is not attached to an AdyenComponent.',
      );
    }
    if (!_isReady) {
      throw StateError(
        'Cannot submit before the component is ready.',
      );
    }
    if (_submit == null) {
      throw StateError(
        'Component submission is not available.',
      );
    }
    return _submit!();
  }

  void _attach(Future<void> Function() submit) {
    if (_disposed) {
      throw StateError(
        'Cannot attach a disposed AdyenComponentController.',
      );
    }
    if (_attached) {
      throw StateError(
        'AdyenComponentController is already attached to a component.',
      );
    }
    _attached = true;
    _submit = submit;
  }

  void _markReady(bool requiresUserInteraction) {
    if (_disposed || !_attached) return;
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

/// Attaches [controller] to a component that provides [submit].
///
/// This is an internal helper. It is not exported from the package barrel file.
void attachAdyenComponentController(
  AdyenComponentController controller,
  Future<void> Function() submit,
) =>
    controller._attach(submit);

/// Marks [controller] as ready with the native [requiresUserInteraction] value.
///
/// This is an internal helper. It is not exported from the package barrel file.
void markAdyenComponentControllerReady(
  AdyenComponentController controller,
  bool requiresUserInteraction,
) =>
    controller._markReady(requiresUserInteraction);

/// Detaches [controller] from its component without disposing it.
///
/// This is an internal helper. It is not exported from the package barrel file.
void detachAdyenComponentController(AdyenComponentController controller) =>
    controller._detach();
