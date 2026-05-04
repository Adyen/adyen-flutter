import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';

class ApplePayDeferredPaymentRequest {
  final String paymentDescription;
  final ApplePayDeferredPaymentSummaryItem deferredBilling;
  final String managementUrl;
  final String? billingAgreement;
  final String? tokenNotificationUrl;
  final DateTime? freeCancellationDate;
  final String? freeCancellationTimeZone;

  const ApplePayDeferredPaymentRequest({
    required this.paymentDescription,
    required this.deferredBilling,
    required this.managementUrl,
    this.billingAgreement,
    this.tokenNotificationUrl,
    this.freeCancellationDate,
    this.freeCancellationTimeZone,
  });
}

class ApplePayDeferredPaymentSummaryItem extends ApplePaySummaryItem {
  final DateTime deferredDate;

  ApplePayDeferredPaymentSummaryItem({
    required super.label,
    required super.amount,
    required super.type,
    required this.deferredDate,
  });
}
