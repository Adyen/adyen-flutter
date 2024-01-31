import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class GooglePayConfiguration {
  final GooglePayEnvironment googlePayEnvironment;
  final String? merchantAccount;
  final TotalPriceStatus? totalPriceStatus;
  final List<String>? allowedCardNetworks;
  final List<CardAuthMethod>? allowedAuthMethods;
  final bool? allowPrepaidCards;
  final bool? billingAddressRequired;
  final bool? emailRequired;
  final bool? shippingAddressRequired;
  final bool? existingPaymentMethodRequired;

  const GooglePayConfiguration({
    required this.googlePayEnvironment,
    this.merchantAccount,
    this.totalPriceStatus,
    this.allowedCardNetworks,
    this.allowedAuthMethods,
    this.allowPrepaidCards,
    this.billingAddressRequired,
    this.emailRequired,
    this.shippingAddressRequired,
    this.existingPaymentMethodRequired,
  });
}
