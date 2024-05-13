import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/components/instant/instant_advanced_component.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';
import 'package:flutter/widgets.dart';

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

  Future<PaymentResult> startInstantComponent({
    required InstantComponentConfiguration configuration,
    required Map<String, dynamic> paymentMethodResponse,
    required AdvancedCheckoutPreview checkout,
  }) async {
    final componentId = "INSTANT_ADVANCED_COMPONENT_${UniqueKey().toString()}";
    return await InstantAdvancedComponent(
      componentId: componentId,
      advancedCheckout: checkout,
    ).start(
      configuration,
      paymentMethodResponse,
    );
  }
}
