import 'package:adyen_checkout/src/common/model/payment_event.dart';

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
  Future<PaymentEvent> Function(String paymentComponentJson) onSubmit;
  Future<PaymentEvent> Function(String additionalDetailsJson)
      onAdditionalDetails;

  AdvancedCheckout({
    required this.onSubmit,
    required this.onAdditionalDetails,
  });
}
