import 'package:adyen_checkout/src/models/card_component_configuration.dart';
import 'package:adyen_checkout/src/models/payment_flow_outcome.dart';
import 'package:adyen_checkout/src/models/session.dart';

sealed class ComponentPaymentFlow{}

class CardComponentSessionFlow extends ComponentPaymentFlow{
  final CardComponentConfiguration cardComponentConfiguration;
  final Session session;

  CardComponentSessionFlow({
    required this.session,
    required this.cardComponentConfiguration,
  });
}

class CardComponentAdvancedFlow extends ComponentPaymentFlow {
  final CardComponentConfiguration cardComponentConfiguration;
  final String paymentMethods;
  final Future<PaymentFlowOutcome> Function(String) onPayments;
  final Future<PaymentFlowOutcome> Function(String) onPaymentsDetails;

  CardComponentAdvancedFlow({
    required this.cardComponentConfiguration,
    required this.paymentMethods,
    required this.onPayments,
    required this.onPaymentsDetails,
  });
}
