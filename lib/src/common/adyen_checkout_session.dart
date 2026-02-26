import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/components/instant/instant_session_component.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';

class AdyenCheckoutSession {
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider.instance;
  final AdyenCheckoutApi adyenCheckoutApi;
  final DropIn dropIn;

  AdyenCheckoutSession(
    this.adyenCheckoutApi,
    this.dropIn,
  );

  Future<SessionCheckout> setup({
    required SessionResponse sessionResponse,
    required CheckoutConfiguration checkoutConfiguration,
  }) async {
    final sessionDTO = await adyenCheckoutApi.setupSession(
      sessionResponse.toDTO(),
      checkoutConfiguration.toDTO(),
    );
    return SessionCheckout(
      id: sessionDTO.id,
      paymentMethods: jsonDecode(sessionDTO.paymentMethodsJson),
    );
  }

  Future<PaymentResult> startDropIn({
    required DropInConfiguration dropInConfiguration,
    required SessionCheckout checkout,
  }) =>
      dropIn.startDropInSessionsPayment(
        dropInConfiguration,
        checkout,
      );

  Future<void> stopDropIn() async => await dropIn.stopDropIn();

  Future<void> clear() async => await adyenCheckoutApi.clearSession();

  Future<PaymentResult> startInstantComponent({
    required InstantComponentConfiguration configuration,
    required Map<String, dynamic> paymentMethod,
    required SessionCheckout checkout,
  }) =>
      InstantSessionComponent(sessionCheckout: checkout).start(
        configuration,
        paymentMethod,
      );
}
