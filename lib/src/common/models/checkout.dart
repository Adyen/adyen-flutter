import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/models/payment_outcome.dart';

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
  Future<PaymentOutcome> Function(String paymentComponentJson) postPayments;
  Future<PaymentOutcome> Function(String additionalDetailsJson)
      postPaymentsDetails;

  AdvancedCheckout({
    required this.postPayments,
    required this.postPaymentsDetails,
  });
}
