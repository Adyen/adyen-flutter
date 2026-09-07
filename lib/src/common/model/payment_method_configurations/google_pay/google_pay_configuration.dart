import '../../google_pay_environment.dart';
import '../../total_price_status.dart';
import 'merchant_info.dart';
import 'shipping_address_parameters.dart';

class GooglePayConfiguration {
  final GooglePayEnvironment googlePayEnvironment;
  final String? merchantAccount;
  final MerchantInfo? merchantInfo;
  final TotalPriceStatus? totalPriceStatus;
  final bool? emailRequired;
  final bool? existingPaymentMethodRequired;
  final bool? shippingAddressRequired;
  final ShippingAddressParameters? shippingAddressParameters;

  const GooglePayConfiguration({
    required this.googlePayEnvironment,
    this.merchantAccount,
    this.merchantInfo,
    this.totalPriceStatus,
    this.emailRequired,
    this.existingPaymentMethodRequired,
    this.shippingAddressRequired,
    this.shippingAddressParameters,
  });

  @override
  String toString() => 'GooglePayConfiguration('
      'googlePayEnvironment: $googlePayEnvironment, '
      'merchantAccount: $merchantAccount, '
      'merchantInfo: $merchantInfo, '
      'totalPriceStatus: $totalPriceStatus, '
      'emailRequired: $emailRequired, '
      'existingPaymentMethodRequired: $existingPaymentMethodRequired, '
      'shippingAddressRequired: $shippingAddressRequired, '
      'shippingAddressParameters: $shippingAddressParameters)';
}
