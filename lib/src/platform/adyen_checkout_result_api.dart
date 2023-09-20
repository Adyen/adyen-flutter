import 'dart:async';

import 'package:adyen_checkout/src/generated/platform_api.g.dart';


class AdyenCheckoutResultApi implements CheckoutFlutterApi {
  var dropInSessionResultStream = StreamController<PaymentResultDTO>();
  var dropInAdvancedFlowPlatformCommunicationStream =
      StreamController<PlatformCommunicationModel>();

  @override
  void onDropInSessionResult(PaymentResultDTO sessionDropInResult) =>
      dropInSessionResultStream.sink.add(sessionDropInResult);

  @override
  void onDropInAdvancedFlowPlatformCommunication(
          PlatformCommunicationModel data) =>
      dropInAdvancedFlowPlatformCommunicationStream.sink.add(data);
}
