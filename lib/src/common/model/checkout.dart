import 'package:adyen_checkout/src/common/model/card_callbacks/card_callbacks.dart';
import 'package:adyen_checkout/src/common/model/partial_payment/partial_payment.dart';
import 'package:adyen_checkout/src/common/model/payment_event.dart';

sealed class Checkout {}

class SessionCheckout extends Checkout {
  final String id;
  final String sessionData;
  final Map<String, dynamic> paymentMethods;
  CardCallbacks? cardCallbacks;

  SessionCheckout({
    required this.id,
    required this.sessionData,
    required this.paymentMethods,
    this.cardCallbacks,
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
  CardCallbacks? cardCallbacks;

  AdvancedCheckout({
    required this.onSubmit,
    required this.onAdditionalDetails,
    this.partialPayment,
    this.cardCallbacks,
  });
}
