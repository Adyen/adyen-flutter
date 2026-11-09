import '../../../../components/apple_pay/model/apple_pay_button_style.dart';
import '../../amount.dart';
import 'apple_pay_contact.dart';
import 'apple_pay_contact_field.dart';
import 'apple_pay_shipping_method.dart';
import 'apple_pay_shipping_type.dart';
import 'apple_pay_summary_item.dart';
import 'apple_pay_merchant_capability.dart';

class ApplePayConfiguration {
  final String merchantId;
  final String merchantName;
  final Amount amount;
  final String countryCode;
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
  // TODO: Map buttonWidth and buttonHeight to ApplePayButtonAppearance and
  // remove the deprecation once the native iOS SDK supports a custom button size.
  @Deprecated('Ignored. The native Apple Pay button fills the component width '
      'and has a fixed height. Wrap CheckoutPaymentComponent in a SizedBox to '
      'control its width.')
  final double? buttonWidth;
  @Deprecated('Ignored. The native Apple Pay button fills the component width '
      'and has a fixed height. Wrap CheckoutPaymentComponent in a SizedBox to '
      'control its width.')
  final double? buttonHeight;

  const ApplePayConfiguration({
    required this.merchantId,
    required this.merchantName,
    required this.amount,
    required this.countryCode,
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
  });
}
