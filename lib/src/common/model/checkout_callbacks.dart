import 'before_submit.dart';
import 'checkout_error.dart';
import 'checkout_results.dart';
import 'action_component_data.dart';
import 'payment_component_data.dart';

typedef SessionCompleteCallback = void Function(SessionCheckoutResult result);
typedef CheckoutFailureCallback = void Function(CheckoutError error);
typedef SubmitCallback = Future<SubmitResult> Function(
    PaymentComponentData data);
typedef AdditionalDetailsCallback = Future<AdditionalDetailsResult> Function(
    ActionComponentData data);

class SessionCheckoutCallbacks {
  final SessionCompleteCallback onComplete;
  final CheckoutFailureCallback onFailure;
  final OnBeforeSubmitCallback? onBeforeSubmit;

  const SessionCheckoutCallbacks({
    required this.onComplete,
    required this.onFailure,
    this.onBeforeSubmit,
  });
}

class AdvancedCheckoutCallbacks {
  final SubmitCallback onSubmit;
  final AdditionalDetailsCallback onAdditionalDetails;
  final CheckoutFailureCallback onFailure;
  final void Function(AdvancedCheckoutResult result) onComplete;

  const AdvancedCheckoutCallbacks({
    required this.onSubmit,
    required this.onAdditionalDetails,
    required this.onFailure,
    required this.onComplete,
  });
}
