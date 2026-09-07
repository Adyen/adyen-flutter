import '../../../../components/apple_pay/model/apple_pay_button_style.dart';
import 'apple_pay_authorization_result.dart';
import 'apple_pay_authorized_payment.dart';
import 'apple_pay_contact.dart';
import 'apple_pay_contact_field.dart';
import 'apple_pay_coupon_code_update.dart';
import 'apple_pay_shipping_contact_update.dart';
import 'apple_pay_shipping_method.dart';
import 'apple_pay_shipping_method_update.dart';
import 'apple_pay_shipping_type.dart';
import 'apple_pay_summary_item.dart';
import 'apple_pay_merchant_capability.dart';

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
  final ApplePayButtonStyle? buttonStyle;
  final double? buttonWidth;
  final double? buttonHeight;
  final Future<ApplePayShippingMethodUpdate> Function(
    ApplePayShippingMethod method,
    List<ApplePaySummaryItem> currentSummaryItems,
  )? onSelectShippingMethod;
  final Future<ApplePayShippingContactUpdate> Function(
    ApplePayContact contact,
    List<ApplePaySummaryItem> currentSummaryItems,
  )? onSelectShippingContact;
  final Future<ApplePayCouponCodeUpdate> Function(
    String couponCode,
    List<ApplePaySummaryItem> currentSummaryItems,
  )? onChangeCouponCode;
  final Future<ApplePayAuthorizationResult> Function(
    ApplePayAuthorizedPayment payment,
  )? onAuthorize;

  const ApplePayConfiguration({
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
    this.buttonStyle,
    this.buttonWidth,
    this.buttonHeight,
    this.onSelectShippingMethod,
    this.onSelectShippingContact,
    this.onChangeCouponCode,
    this.onAuthorize,
  });
}
