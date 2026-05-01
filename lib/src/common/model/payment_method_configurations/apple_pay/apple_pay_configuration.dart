import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_contact.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_contact_field.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_coupon_code_update.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_shipping_contact_update.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_shipping_method.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_shipping_method_update.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_summary_item.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class ApplePayConfiguration {
  final String merchantId;
  final String merchantName;
  final bool? allowOnboarding;
  final List<ApplePaySummaryItem>? applePaySummaryItems;
  final List<ApplePayContactField>? requiredBillingContactFields;
  final ApplePayContact? billingContact;
  final List<ApplePayContactField>? requiredShippingContactFields;
  final ApplePayContact? shippingContact;
  final ApplePayShippingType? applePayShippingType;
  final bool? allowShippingContactEditing;
  final List<ApplePayShippingMethod>? shippingMethods;
  final String? applicationData;
  final List<String>? supportedCountries;
  final ApplePayMerchantCapability? merchantCapability;
  final bool? supportsCouponCode;
  final String? couponCode;
  final Future<ApplePayShippingMethodUpdate> Function(
    ApplePayShippingMethod method,
    List<ApplePaySummaryItem> currentSummaryItems,
  )? onShippingMethodChange;
  final Future<ApplePayShippingContactUpdate> Function(
    ApplePayContact contact,
    List<ApplePaySummaryItem> currentSummaryItems,
  )? onShippingContactChange;
  final Future<ApplePayCouponCodeUpdate> Function(
    String couponCode,
    List<ApplePaySummaryItem> currentSummaryItems,
  )? onCouponCodeChange;

  ApplePayConfiguration({
    required this.merchantId,
    required this.merchantName,
    this.allowOnboarding,
    this.applePaySummaryItems,
    this.requiredBillingContactFields,
    this.billingContact,
    this.requiredShippingContactFields,
    this.shippingContact,
    this.applePayShippingType,
    this.allowShippingContactEditing,
    this.shippingMethods,
    this.applicationData,
    this.supportedCountries,
    this.merchantCapability,
    this.supportsCouponCode,
    this.couponCode,
    this.onShippingMethodChange,
    this.onShippingContactChange,
    this.onCouponCodeChange,
  });

  @override
  String toString() {
    return 'ApplePayConfiguration('
        'merchantId: $merchantId, '
        'merchantName: $merchantName, '
        'allowOnboarding: $allowOnboarding, '
        'applePaySummaryItems: $applePaySummaryItems, '
        'requiredBillingContactFields: $requiredBillingContactFields, '
        'billingContact: $billingContact, '
        'requiredShippingContactFields: $requiredShippingContactFields, '
        'shippingContact: $shippingContact, '
        'applePayShippingType: $applePayShippingType, '
        'allowShippingContactEditing: $allowShippingContactEditing, '
        'shippingMethods: $shippingMethods, '
        'applicationData: $applicationData, '
        'supportedCountries: $supportedCountries, '
        'merchantCapability: $merchantCapability, '
        'supportsCouponCode: $supportsCouponCode, '
        'couponCode: $couponCode, '
        'onShippingMethodChange: $onShippingMethodChange, '
        'onShippingContactChange: $onShippingContactChange, '
        'onCouponCodeChange: $onCouponCodeChange)';
  }
}
