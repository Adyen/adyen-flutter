import 'apple_pay_contact.dart';
import 'apple_pay_shipping_method.dart';

class ApplePayAuthorizedPayment {
  final String token;
  final String network;
  final ApplePayContact? billingContact;
  final ApplePayContact? shippingContact;
  final ApplePayShippingMethod? shippingMethod;

  const ApplePayAuthorizedPayment({
    required this.token,
    required this.network,
    this.billingContact,
    this.shippingContact,
    this.shippingMethod,
  });
}
