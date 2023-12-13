import 'package:adyen_checkout/adyen_checkout.dart';

sealed class ComponentPaymentFlow {}

class CardComponentSessionFlow extends ComponentPaymentFlow {
  final Session session;
  final Map<String, dynamic> paymentMethod;

  CardComponentSessionFlow({
    required this.session,
    Map<String, dynamic>? paymentMethod,
  }) : paymentMethod = paymentMethod ?? <String, String>{};
}

class CardComponentAdvancedFlow extends ComponentPaymentFlow {
  final Map<String, dynamic>? paymentMethod;
  final Future<PaymentFlowOutcome> Function(String) onPayments;
  final Future<PaymentFlowOutcome> Function(String) onPaymentsDetails;

  CardComponentAdvancedFlow({
    required this.paymentMethod,
    required this.onPayments,
    required this.onPaymentsDetails,
  });
}
