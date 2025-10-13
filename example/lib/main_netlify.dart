import 'package:adyen_checkout_example/main_common.dart';
import 'package:adyen_checkout_example/network/netlify_service.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension();
  mainCommon(NetlifyService());
}
