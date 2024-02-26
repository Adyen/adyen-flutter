import 'package:adyen_checkout/src/common/model/billing_address_parameters.dart';
import 'package:adyen_checkout/src/common/model/merchant_info.dart';
import 'package:adyen_checkout/src/common/model/shipping_address_parameters.dart';
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
}
