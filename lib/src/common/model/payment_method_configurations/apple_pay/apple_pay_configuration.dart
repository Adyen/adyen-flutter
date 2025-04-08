import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_contact.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_contact_field.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_shipping_method.dart';
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
        'merchantCapability: $merchantCapability)';
  }
}
