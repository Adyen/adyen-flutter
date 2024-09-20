import 'package:adyen_checkout/src/common/model/partial_payment.dart';
import 'package:adyen_checkout/src/common/model/payment_event.dart';

sealed class Checkout {}

class SessionCheckout extends Checkout {
  final String id;
  final String sessionData;
  final Map<String, dynamic> paymentMethods;

  SessionCheckout({
    required this.id,
    required this.sessionData,
    required this.paymentMethods,
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
    required this.onSubmit,
    required this.onAdditionalDetails,
    this.partialPayment,
  });
}
