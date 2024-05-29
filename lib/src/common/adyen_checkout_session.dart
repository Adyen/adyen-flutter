import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/common/model/base_configuration.dart';
import 'package:adyen_checkout/src/components/instant/instant_session_component.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
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

  Future<PaymentResult> startDropIn({
    required DropInConfiguration dropInConfiguration,
    required SessionCheckout checkout,
  }) =>
      dropIn.startDropInSessionsPayment(
        dropInConfiguration,
        checkout,
      );

  Future<SessionCheckout> create({
    required String sessionId,
    required String sessionData,
    required BaseConfiguration configuration,
  }) async {
    final sdkVersionNumber =
        await _sdkVersionNumberProvider.getSdkVersionNumber();

    SessionDTO sessionDTO = await adyenCheckoutApi.createSession(
      sessionId,
      sessionData,
      _mapConfiguration(configuration, sdkVersionNumber),
    );

    return SessionCheckout(
      id: sessionDTO.id,
      sessionData: sessionDTO.sessionData,
      paymentMethods: jsonDecode(sessionDTO.paymentMethodsJson),
    );
  }

  dynamic _mapConfiguration(
    BaseConfiguration configuration,
    String sdkVersionNumber,
  ) {
    if (configuration is CardComponentConfiguration) {
      return configuration.toDTO(sdkVersionNumber);
    } else if (configuration is GooglePayComponentConfiguration) {
      return configuration.toDTO(
        sdkVersionNumber,
        InstantPaymentType.googlePay,
      );
    } else if (configuration is ApplePayComponentConfiguration) {
      return configuration.toDTO(
        sdkVersionNumber,
        InstantPaymentType.applePay,
      );
    } else if (configuration is DropInConfiguration) {
      return configuration.toDTO(sdkVersionNumber);
    } else if (configuration is InstantComponentConfiguration) {
      return configuration.toDTO(
        sdkVersionNumber,
        InstantPaymentType.instant,
      );
    }
  }

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
