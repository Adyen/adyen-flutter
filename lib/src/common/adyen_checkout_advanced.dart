import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
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
    AdvancedCheckout? checkout,
    AdvancedCheckoutPreview? advancedCheckoutPreview,
  }) {
    final Checkout? advancedCheckout = advancedCheckoutPreview ?? checkout;
    if (advancedCheckout == null) {
      throw Exception("Please provide the advancedCheckoutPreview");
    }

    return dropIn.startDropInAdvancedFlowPayment(
      dropInConfiguration,
      paymentMethodsResponse,
      advancedCheckout,
    );
  }
}
