import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/adyen_checkout_result_api.dart';

class AdyenCheckout {
  AdyenCheckout() {
    _setupCheckoutResultApi();
  }

  final AdyenCheckoutResultApi _adyenCheckoutResultApi =
      AdyenCheckoutResultApi();

  Future<String> getPlatformVersion() {
    return AdyenCheckoutInterface.instance.getPlatformVersion();
  }

  Future<SessionDropInResultModel> startDropInSessionsPayment(
    SessionModel sessionModel,
    DropInConfigurationModel dropInConfiguration,
  ) async {
    _adyenCheckoutResultApi.sessionDropInResultStream =
        StreamController<SessionDropInResultModel>();

    AdyenCheckoutInterface.instance.startPayment(
      sessionModel,
      dropInConfiguration,
    );

    final sessionDropInResultModel =
        await _adyenCheckoutResultApi.sessionDropInResultStream.stream.first;
    await _adyenCheckoutResultApi.sessionDropInResultStream.close();
    return sessionDropInResultModel;
  }

  Future<String> getReturnUrl() {
    return AdyenCheckoutInterface.instance.getReturnUrl();
  }

  void _setupCheckoutResultApi() =>
      CheckoutResultFlutterInterface.setup(_adyenCheckoutResultApi);
}
