import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_contact.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_shipping_method.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ApplePayConfiguration {
  final String merchantId;
  final String merchantName;
  final bool? allowOnboarding;
  final List<String>? supportedNetworks;
  final List<String>? requiredBillingContactFields;
  final ApplePayContact? billingContact;
  final List<String>? requiredShippingContactFields;
  final ApplePayContact? shippingContact;
  final ApplePayShippingType? applePayShippingType;
  final bool? allowShippingContactEditing;
  final List<ApplePayShippingMethod>? shippingMethods;
  final String? applicationData;
  final List<String>? supportedCountries;
  final bool? supportsCouponCode;
  final String? couponCode;
  final ApplePayFundingSource? merchantCapability;

  ApplePayConfiguration({
    required this.merchantId,
    required this.merchantName,
    this.allowOnboarding,
    this.supportedNetworks,
    this.requiredBillingContactFields,
    this.billingContact,
    this.requiredShippingContactFields,
    this.shippingContact,
    this.applePayShippingType,
    this.allowShippingContactEditing,
    this.shippingMethods,
    this.applicationData,
    this.supportedCountries,
    this.supportsCouponCode,
    this.couponCode,
    this.merchantCapability,
  });
}
