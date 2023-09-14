import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/models/drop_in_outcome.dart';

sealed class PaymentFlow {}

class DropInSession extends PaymentFlow {
  final DropInConfigurationDTO dropInConfiguration;
  final Session session;

  DropInSession({
    required this.dropInConfiguration,
    required this.session,
  });
}

class DropInAdvancedFlow extends PaymentFlow {
  final DropInConfigurationDTO dropInConfiguration;
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
