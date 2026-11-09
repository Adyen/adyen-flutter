import 'apple_pay_authorization_result.dart';
import 'apple_pay_authorized_payment.dart';
import 'apple_pay_contact.dart';
import 'apple_pay_coupon_code_update.dart';
import 'apple_pay_shipping_contact_update.dart';
import 'apple_pay_shipping_method.dart';
import 'apple_pay_shipping_method_update.dart';
import 'apple_pay_summary_item.dart';

class ApplePayCallbacks {
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

  const ApplePayCallbacks({
    this.onSelectShippingMethod,
    this.onSelectShippingContact,
    this.onChangeCouponCode,
    this.onAuthorize,
  });
}
