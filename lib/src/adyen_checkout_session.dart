import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/common/models/base_configuration.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/utils/dto_mapper.dart';
import 'package:adyen_checkout/src/utils/sdk_version_number_provider.dart';

class AdyenCheckoutSession implements AdyenCheckoutSessionInterface {
  final SdkVersionNumberProvider _sdkVersionNumberProvider =
      SdkVersionNumberProvider();
  late final AdyenCheckoutApi adyenCheckoutApi;
  late final DropIn _dropIn =
      DropIn(sdkVersionNumberProvider: _sdkVersionNumberProvider);

  AdyenCheckoutSession(this.adyenCheckoutApi);

  @override
  Future<PaymentResult> startDropIn({
    required DropInConfiguration dropInConfiguration,
    required SessionCheckout checkout,
  }) async {
    return _dropIn.startDropInSessionsPayment(
      dropInConfiguration,
      checkout,
    );
  }

  @override
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
      paymentMethodsJson: sessionDTO.paymentMethodsJson,
    );
  }

  dynamic _mapConfiguration(
    BaseConfiguration configuration,
    String sdkVersionNumber,
  ) {
    if (configuration is CardComponentConfiguration) {
      return configuration.toDTO(sdkVersionNumber);
    } else if (configuration is DropInConfiguration) {
      return configuration.toDTO(sdkVersionNumber);
    }
  }
}

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
