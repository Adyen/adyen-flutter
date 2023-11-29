import 'package:adyen_checkout/adyen_checkout.dart';

sealed class ComponentPaymentFlow {}

class CardComponentSessionFlow extends ComponentPaymentFlow {
  final CardComponentConfiguration cardComponentConfiguration;
  final Session session;

  CardComponentSessionFlow({
    required this.cardComponentConfiguration,
    required this.session,
  });
}

class CardComponentAdvancedFlow extends ComponentPaymentFlow {
  final CardComponentConfiguration cardComponentConfiguration;
  final Map<String, dynamic> paymentMethod;
  final Future<PaymentFlowOutcome> Function(String) onPayments;
  final Future<PaymentFlowOutcome> Function(String) onPaymentsDetails;

  CardComponentAdvancedFlow({
    required this.cardComponentConfiguration,
    required this.paymentMethod,
    required this.onPayments,
    required this.onPaymentsDetails,
  });
}
