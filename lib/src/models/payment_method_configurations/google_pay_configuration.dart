import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class GooglePayConfiguration {
  final GooglePayEnvironment googlePayEnvironment;
  final String? merchantAccount;
  final List<String> allowedCardNetworks;
  final List<CardAuthMethod> allowedAuthMethods;
  final TotalPriceStatus? totalPriceStatus;
  final bool allowPrepaidCards;
  final bool billingAddressRequired;
  final bool emailRequired;
  final bool shippingAddressRequired;
  final bool existingPaymentMethodRequired;

  GooglePayConfiguration({
    required this.googlePayEnvironment,
    this.merchantAccount,
    this.totalPriceStatus,
    this.allowedCardNetworks = const [],
    this.allowedAuthMethods = const [],
    this.allowPrepaidCards = true,
    this.billingAddressRequired = false,
    this.emailRequired = false,
    this.shippingAddressRequired = false,
    this.existingPaymentMethodRequired = false,
  });
}
