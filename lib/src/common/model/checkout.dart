import 'package:adyen_checkout/src/common/model/before_submit.dart';
import 'package:adyen_checkout/src/common/model/partial_payment/partial_payment.dart';
import 'package:adyen_checkout/src/common/model/payment_event.dart';

sealed class Checkout {
  final Map<String, dynamic> paymentMethods;

  Checkout({required this.paymentMethods});
}

class SessionCheckout extends Checkout {
  final String id;

  /// Called before the sessions flow submits payment data. See
  /// [OnBeforeSubmitCallback].
  final OnBeforeSubmitCallback? onBeforeSubmit;

  SessionCheckout({
    required this.id,
    required super.paymentMethods,
    this.onBeforeSubmit,
  });
}

class AdvancedCheckout extends Checkout {
  Future<PaymentEvent> Function(
    Map<String, dynamic> data, [
    Map<String, dynamic>? extra,
  ]) onSubmit;

  Future<PaymentEvent> Function(Map<String, dynamic> additionalDetails)
      onAdditionalDetails;

  PartialPayment? partialPayment;

  AdvancedCheckout({
    required super.paymentMethods,
    required this.onSubmit,
    required this.onAdditionalDetails,
    this.partialPayment,
  });
}
