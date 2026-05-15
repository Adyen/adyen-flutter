import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ApplePayRecurringPaymentRequest {
  final String paymentDescription;
  final ApplePayRecurringPaymentSummaryItem regularBilling;
  final String managementUrl;
  final ApplePayRecurringPaymentSummaryItem? trialBilling;
  final String? billingAgreement;
  final String? tokenNotificationUrl;

  const ApplePayRecurringPaymentRequest({
    required this.paymentDescription,
    required this.regularBilling,
    required this.managementUrl,
    this.trialBilling,
    this.billingAgreement,
    this.tokenNotificationUrl,
  });
}

class ApplePayRecurringPaymentSummaryItem extends ApplePaySummaryItem {
  final DateTime? startDate;
  final ApplePayRecurringPaymentIntervalUnit? intervalUnit;
  final int? intervalCount;
  final DateTime? endDate;

  ApplePayRecurringPaymentSummaryItem({
    required super.label,
    required super.amount,
    required super.type,
    this.startDate,
    this.intervalUnit,
    this.intervalCount,
    this.endDate,
  });
}
