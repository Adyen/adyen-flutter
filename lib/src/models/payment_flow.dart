import 'package:adyen_checkout/src/models/adyen_configuration.dart';
import 'package:adyen_checkout/src/models/drop_in_outcome.dart';
import 'package:adyen_checkout/src/models/session.dart';

sealed class PaymentFlow {}

class DropInSession extends PaymentFlow {
  final DropInConfiguration dropInConfiguration;
  final Session session;

  DropInSession({
    required this.dropInConfiguration,
    required this.session,
  });
}

class DropInAdvancedFlow extends PaymentFlow {
  final DropInConfiguration dropInConfiguration;
  final String paymentMethodsResponse;
  Future<DropInOutcome> Function(String paymentComponentJson) postPayments;
  Future<DropInOutcome> Function(String additionalDetailsJson)
      postPaymentsDetails;

  DropInAdvancedFlow({
    required this.dropInConfiguration,
    required this.paymentMethodsResponse,
    required this.postPayments,
    required this.postPaymentsDetails,
  });
}
