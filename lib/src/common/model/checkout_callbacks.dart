import 'action_component_data.dart';
import 'before_submit.dart';
import 'card_callbacks/card_callbacks.dart';
import 'checkout_error.dart';
import 'checkout_results.dart';
import 'payment_method_configurations/apple_pay/apple_pay_callbacks.dart';

typedef CheckoutCompleteCallback = void Function(CheckoutResult result);
typedef CheckoutFailureCallback = void Function(CheckoutError error);
typedef AdditionalDetailsCallback = Future<AdditionalDetailsResult> Function(
    ActionComponentData data);

class CheckoutCallbacks {
  final CheckoutCompleteCallback onComplete;
  final CheckoutFailureCallback onFailure;
  final OnBeforeSubmitCallback? onBeforeSubmit;
  final ApplePayCallbacks? applePay;
  final CardCallbacks? card;

  const CheckoutCallbacks({
    required this.onComplete,
    required this.onFailure,
    this.onBeforeSubmit,
    this.applePay,
    this.card,
  });
}
