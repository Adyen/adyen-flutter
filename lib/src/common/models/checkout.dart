import 'package:adyen_checkout/src/common/models/payment_event.dart';

sealed class Checkout {}

class SessionCheckout extends Checkout {
  final String id;
  final String sessionData;
  final String paymentMethodsJson;

  SessionCheckout({
    required this.id,
    required this.sessionData,
    required this.paymentMethodsJson,
  });
}

class AdvancedCheckout extends Checkout {
  Future<PaymentEvent> Function(String paymentComponentJson) postPayments;
  Future<PaymentEvent> Function(String additionalDetailsJson)
      postPaymentsDetails;

  AdvancedCheckout({
    required this.postPayments,
    required this.postPaymentsDetails,
  });
}
