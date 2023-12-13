import 'package:adyen_checkout/src/common/models/checkout.dart';
import 'package:adyen_checkout/src/common/models/payment_result.dart';
import 'package:adyen_checkout/src/drop_in/models/drop_in_configuration.dart';

abstract class AdyenCheckoutAdvancedInterface {
  Future<PaymentResult> startDropIn({
    required DropInConfiguration dropInConfiguration,
    required String paymentMethodsResponse,
    required AdvancedCheckout checkout,
  });
}
