import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/components/instant/instant_advanced_component.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';

class AdyenCheckoutAdvanced {
  final AdyenCheckoutApi adyenCheckoutApi;
  final DropIn dropIn;

  AdyenCheckoutAdvanced(
    this.adyenCheckoutApi,
    this.dropIn,
  );

  Future<void> setup({
    required Map<String, dynamic> paymentMethods,
    required CheckoutConfiguration checkoutConfiguration,
  }) async {
    final encodedPaymentMethodsResponse = jsonEncode(
      paymentMethods,
      toEncodable: (value) => throw Exception("Could not encode $value"),
    );
    await adyenCheckoutApi.setupAdvanced(
      encodedPaymentMethodsResponse,
      checkoutConfiguration.toDTO("2.0"),
    );
  }

  Future<PaymentResult> startDropIn({
    required DropInConfiguration dropInConfiguration,
    required Map<String, dynamic> paymentMethods,
    required AdvancedCheckout checkout,
  }) =>
      dropIn.startDropInAdvancedFlowPayment(
        dropInConfiguration,
        paymentMethods,
        checkout,
      );

  Future<PaymentResult> startInstantComponent({
    required InstantComponentConfiguration configuration,
    required Map<String, dynamic> paymentMethod,
    required AdvancedCheckout checkout,
  }) =>
      InstantAdvancedComponent(advancedCheckout: checkout).start(
        configuration,
        paymentMethod,
      );

  Future<void> stopDropIn() async => await dropIn.stopDropIn();
}
