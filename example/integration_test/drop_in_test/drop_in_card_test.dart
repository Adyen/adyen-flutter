import 'dart:io';

import 'package:adyen_checkout_example/main.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'Drop-in test',
    ($) async {
      await $.pumpWidget(adyenExampleApp());
      await $('Drop-in').tap();
      await $('Drop-in sessions').tap();
      await $.native.waitUntilVisible(Selector(text: "Cards"));
      await $.native.tap(Selector(text: "Cards"));
      await $.native.waitUntilVisible(Selector(text: "Card number"));
      await $.native.enterText(
        Selector(text: 'Card number'),
        text: '4111 1111 1111 1111',
      );
      if (Platform.isAndroid) {
        await $.native.enterText(Selector(text: 'Expiry date'), text: '0330');
        await $.native.enterText(Selector(text: 'CVC / CVV'), text: '737');
        await $.native.tap(Selector(textStartsWith: "PAY"));
      } else {
        //Adding the CVC in one go is a workaround for iOS because of an animation blocking the security field input.
        await $.native.enterText(
          Selector(text: 'Expiry date'),
          text: '0330 737',
        );
        await $.native.tap(Selector(textStartsWith: "Pay"));
      }

      await $.waitUntilVisible($("Finished"));
      await $('Close').tap();
    },
  );
}
