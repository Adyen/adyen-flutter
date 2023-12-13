import 'package:adyen_checkout/src/common/models/base_configuration.dart';
import 'package:adyen_checkout/src/common/models/checkout.dart';
import 'package:adyen_checkout/src/common/models/payment_result.dart';
import 'package:adyen_checkout/src/drop_in/models/drop_in_configuration.dart';

abstract class AdyenCheckoutSessionInterface {
  Future<PaymentResult> startDropIn({
    required DropInConfiguration dropInConfiguration,
    required SessionCheckout checkout,
  });

  Future<SessionCheckout> create({
    required String sessionId,
    required String sessionData,
    required BaseConfiguration configuration,
  });
}
