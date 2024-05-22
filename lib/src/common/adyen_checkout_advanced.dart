import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/components/instant/instant_advanced_component.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';

class AdyenCheckoutAdvanced {
  final AdyenCheckoutApi adyenCheckoutApi;
  final DropIn dropIn;

  AdyenCheckoutAdvanced(
    this.adyenCheckoutApi,
    this.dropIn,
  );

  Future<PaymentResult> startDropIn({
    required DropInConfiguration dropInConfiguration,
    required String paymentMethodsResponse,
    required AdvancedCheckout checkout,
  }) {
    return dropIn.startDropInAdvancedFlowPayment(
      dropInConfiguration,
      paymentMethodsResponse,
      checkout,
    );
  }

  Future<PaymentResult> startInstantComponent({
    required InstantComponentConfiguration configuration,
    required Map<String, dynamic> paymentMethodResponse,
    required AdvancedCheckout checkout,
  }) async {
    return await InstantAdvancedComponent(advancedCheckout: checkout).start(
      configuration,
      paymentMethodResponse,
    );
  }
}
