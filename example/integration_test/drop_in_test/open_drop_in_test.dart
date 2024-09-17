import 'package:adyen_checkout_example/main.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'Open Drop-in sessions',
    ($) async {
      await $.pumpWidget(adyenExampleApp());
      await $('Drop-in').tap();
      await $('Drop-in sessions').tap();
      await $.native.waitUntilVisible(Selector(text: "Cards"));
    },
  );

  patrolTest(
    'Open Drop-in advanced',
    ($) async {
      await $.pumpWidget(adyenExampleApp());
      await $('Drop-in').tap();
      await $('Drop-in advanced').tap();
      await $.native.waitUntilVisible(Selector(text: "Cards"));
    },
  );
}
