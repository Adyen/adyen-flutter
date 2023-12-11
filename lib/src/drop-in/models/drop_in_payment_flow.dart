import 'package:adyen_checkout/adyen_checkout.dart';

sealed class DropInPaymentFlow {}

class DropInSessionFlow extends DropInPaymentFlow {
  final DropInConfiguration dropInConfiguration;
  final Session session;

  DropInSessionFlow({
    required this.dropInConfiguration,
    required this.session,
  });
}

class DropInAdvancedFlow extends DropInPaymentFlow {
  final DropInConfiguration dropInConfiguration;
  final String paymentMethodsResponse;
  Future<PaymentFlowOutcome> Function(String paymentComponentJson) postPayments;
  Future<PaymentFlowOutcome> Function(String additionalDetailsJson)
      postPaymentsDetails;

  DropInAdvancedFlow({
    required this.dropInConfiguration,
    required this.paymentMethodsResponse,
    required this.postPayments,
    required this.postPaymentsDetails,
  });
}
