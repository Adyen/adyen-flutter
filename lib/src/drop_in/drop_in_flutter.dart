import 'dart:async';

import 'package:adyen_checkout/src/generated/platform_api.g.dart';

class DropInFlutter implements CheckoutFlutterInterface {
  StreamController<CheckoutEvent>? platformEventStream;

  @override
  void send(CheckoutEvent event) => platformEventStream?.sink.add(event);
}
