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

@Deprecated(
    "Please consider using the AdvancedCheckoutPreview. We plan for adaptation with the first beta release.")
class AdvancedCheckout extends Checkout {
  Future<PaymentEvent> Function(String paymentComponentJson) onSubmit;
  Future<PaymentEvent> Function(String additionalDetailsJson)
      onAdditionalDetails;

  AdvancedCheckout({
    required this.onSubmit,
    required this.onAdditionalDetails,
  });
}

class AdvancedCheckoutPreview extends Checkout {
  Future<PaymentEvent> Function(
    Map<String, dynamic> data, [
    Map<String, dynamic>? extra,
  ]) onSubmit;

  Future<PaymentEvent> Function(Map<String, dynamic> additionalDetails)
      onAdditionalDetails;

  AdvancedCheckoutPreview({
    required this.onSubmit,
    required this.onAdditionalDetails,
  });
}
