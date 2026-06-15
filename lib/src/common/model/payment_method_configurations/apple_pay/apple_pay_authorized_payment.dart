import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_contact.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/apple_pay/apple_pay_shipping_method.dart';

class ApplePayAuthorizedPayment {
  final String token;
  final String network;
  final ApplePayContact? billingContact;
  final ApplePayContact? shippingContact;
  final ApplePayShippingMethod? shippingMethod;

  ApplePayAuthorizedPayment({
    required this.token,
    required this.network,
    this.billingContact,
    this.shippingContact,
    this.shippingMethod,
  });

  @override
  String toString() {
    return 'ApplePayAuthorizedPayment('
        'network: $network, '
        'billingContact: $billingContact, '
        'shippingContact: $shippingContact, '
        'shippingMethod: $shippingMethod)';
  }
}
