import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/models/drop_in_outcome.dart';
import 'package:adyen_checkout/src/models/payment_type.dart';

class PaymentFlow {
  late final PaymentType paymentType;
  final DropInConfiguration dropInConfiguration;
  String? componentConfiguration;
  Session? session;
  String? paymentMethodsResponse;
  Future<DropInOutcome> Function(String paymentComponentJson)? postPayments;
  Future<DropInOutcome> Function(String additionalDetailsJson)?
      postPaymentsDetails;

  PaymentFlow.dropIn({
    required this.dropInConfiguration,
    required this.session,
  }) {
    paymentType = PaymentType.dropInSessions;
  }

  PaymentFlow.dropInAdvanced({
    required this.dropInConfiguration,
    required this.paymentMethodsResponse,
    required this.postPayments,
    required this.postPaymentsDetails,
  }) {
    paymentType = PaymentType.dropInAdvancedFlow;
  }
}
