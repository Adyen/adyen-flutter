import 'package:adyen_checkout/src/common/model/payment_method_configurations/google_pay/billing_address_parameters.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/google_pay/merchant_info.dart';
import 'package:adyen_checkout/src/common/model/payment_method_configurations/google_pay/shipping_address_parameters.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class GooglePayConfiguration {
  final GooglePayEnvironment googlePayEnvironment;
  final String? merchantAccount;
  final MerchantInfo? merchantInfo;
  final TotalPriceStatus? totalPriceStatus;
  final List<String>? allowedCardNetworks;
  final List<CardAuthMethod>? allowedAuthMethods;
  final bool? allowPrepaidCards;
  final bool? allowCreditCards;
  final bool? assuranceDetailsRequired;
  final bool? emailRequired;
  final bool? existingPaymentMethodRequired;
  final bool? shippingAddressRequired;
  final ShippingAddressParameters? shippingAddressParameters;
  final bool? billingAddressRequired;
  final BillingAddressParameters? billingAddressParameters;

  const GooglePayConfiguration({
    required this.googlePayEnvironment,
    this.merchantAccount,
    this.merchantInfo,
    this.totalPriceStatus,
    this.allowedCardNetworks,
    this.allowedAuthMethods,
    this.allowPrepaidCards,
    this.allowCreditCards,
    this.assuranceDetailsRequired,
    this.emailRequired,
    this.existingPaymentMethodRequired,
    this.billingAddressRequired,
    this.billingAddressParameters,
    this.shippingAddressRequired,
    this.shippingAddressParameters,
  });

  @override
  String toString() {
    return 'GooglePayConfiguration('
        'googlePayEnvironment: $googlePayEnvironment, '
        'merchantAccount: $merchantAccount, '
        'merchantInfo: $merchantInfo, '
        'totalPriceStatus: $totalPriceStatus, '
        'allowedCardNetworks: $allowedCardNetworks, '
        'allowedAuthMethods: $allowedAuthMethods, '
        'allowPrepaidCards: $allowPrepaidCards, '
        'allowCreditCards: $allowCreditCards, '
        'assuranceDetailsRequired: $assuranceDetailsRequired, '
        'emailRequired: $emailRequired, '
        'existingPaymentMethodRequired: $existingPaymentMethodRequired, '
        'shippingAddressRequired: $shippingAddressRequired, '
        'shippingAddressParameters: $shippingAddressParameters, '
        'billingAddressRequired: $billingAddressRequired, '
        'billingAddressParameters: $billingAddressParameters)';
  }
}
