// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction

import 'package:adyen_checkout_example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DropIn sessions flow test', (WidgetTester tester) async {
    await tester.pumpWidget(const AdyenExampleApp());

    final dropInScreen = find.byKey(const ValueKey('DropInScreen'));
    await tester.tap(dropInScreen);
    await tester.pumpAndSettle();

    final dropInSessions = find.byKey(const ValueKey('DropInSessions'));
    await tester.tap(dropInSessions);
    await tester.pumpAndSettle();

    await Future.delayed(const Duration(seconds: 15));
  });
}
