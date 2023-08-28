import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/models/payment_type.dart';

class PaymentFlow {
  late final PaymentType paymentType;
  final DropInConfigurationModel dropInConfiguration;
  SessionModel? sessionModel;
  String? paymentMethodsResponse;
  Future<Map<String, dynamic>> Function(String paymentComponentJson)?
      postPayments;
  Future<Map<String, dynamic>> Function(String additionalDetailsJson)?
      postPaymentsDetails;

  PaymentFlow.dropInSessions({
    required this.dropInConfiguration,
    required this.sessionModel,
  }) {
    paymentType = PaymentType.dropInSessions;
  }

  PaymentFlow.dropInAdvancedFlow({
    required this.dropInConfiguration,
    required this.paymentMethodsResponse,
    required this.postPayments,
    required this.postPaymentsDetails,
  }) {
    paymentType = PaymentType.dropInAdvancedFlow;
  }
}
