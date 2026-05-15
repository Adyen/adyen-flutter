import 'package:adyen_checkout/src/common/model/amount.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';

class ApplePayReloadPaymentRequest {
  final String paymentDescription;
  final ApplePayReloadPaymentSummaryItem automaticReloadBilling;
  final String managementUrl;
  final String? billingAgreement;
  final String? tokenNotificationUrl;

  const ApplePayReloadPaymentRequest({
    required this.paymentDescription,
    required this.automaticReloadBilling,
    required this.managementUrl,
    this.billingAgreement,
    this.tokenNotificationUrl,
  });
}

class ApplePayReloadPaymentSummaryItem extends ApplePaySummaryItem {
  final Amount thresholdAmount;

  ApplePayReloadPaymentSummaryItem({
    required super.label,
    required super.amount,
    required super.type,
    required this.thresholdAmount,
  });
}
