import 'dart:async';

import 'package:adyen_checkout/platform_api.g.dart';

class AdyenCheckoutResultApi implements CheckoutFlutterApi {
  var dropInSessionResultStream = StreamController<PaymentResult>();
  var dropInAdvancedFlowPlatformCommunicationStream =
      StreamController<PlatformCommunicationModel>();

  @override
  void onDropInSessionResult(PaymentResult sessionDropInResult) =>
      dropInSessionResultStream.sink.add(sessionDropInResult);

  @override
  void onDropInAdvancedFlowPlatformCommunication(
          PlatformCommunicationModel data) =>
      dropInAdvancedFlowPlatformCommunicationStream.sink.add(data);
}
