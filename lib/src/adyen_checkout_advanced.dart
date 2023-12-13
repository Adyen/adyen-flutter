import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';
import 'package:adyen_checkout/src/utils/sdk_version_number_provider.dart';

class AdyenCheckoutAdvanced implements AdyenCheckoutAdvancedInterface {
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider();
  late final AdyenCheckoutApi adyenCheckoutApi;
  late final DropIn _dropIn =
      DropIn(sdkVersionNumberProvider: _sdkVersionNumberProvider);

  AdyenCheckoutAdvanced(this.adyenCheckoutApi);

  @override
  Future<PaymentResult> startDropIn({
    required DropInConfiguration dropInConfiguration,
    required String paymentMethodsResponse,
    required AdvancedCheckout checkout,
  }) async =>
      _dropIn.startDropInAdvancedFlowPayment(
        dropInConfiguration,
        paymentMethodsResponse,
        checkout,
      );
}

abstract class AdyenCheckoutAdvancedInterface {
  Future<PaymentResult> startDropIn({
    required DropInConfiguration dropInConfiguration,
    required String paymentMethodsResponse,
    required AdvancedCheckout checkout,
  });
}
