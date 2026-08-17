import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/platform/component_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComponentContainer', () {
    const initialHeight = 200.0;
    const bottomSpacing = 8.0;

    Future<void> pumpContainer(
      WidgetTester tester, {
      required int? viewportHeight,
      Key? key,
    }) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ComponentContainer(
                componentWidgetKey: key ?? GlobalKey(),
                initialViewPortHeight: initialHeight,
                viewportHeight: viewportHeight,
                componentWidget: const SizedBox.expand(),
              ),
            ),
          ),
        );

    testWidgets('renders component widget at fallback height when viewportHeight is null', (
      tester,
    ) async {
      final key = GlobalKey();
      await pumpContainer(tester, viewportHeight: null, key: key);

      final sizedBox = tester.widget<SizedBox>(find.byKey(key));
      expect(sizedBox.height, initialHeight);
    });

    testWidgets('collapses to zero height when native reports zero height', (tester) async {
      final key = GlobalKey();
      await pumpContainer(tester, viewportHeight: 0, key: key);

      final sizedBox = tester.widget<SizedBox>(find.byKey(key));
      expect(sizedBox.height, 0.0);
    });

    testWidgets('does not add bottom spacing when viewport height is zero', (tester) async {
      final key = GlobalKey();
      await pumpContainer(tester, viewportHeight: 0, key: key);

      final sizedBox = tester.widget<SizedBox>(find.byKey(key));
      expect(sizedBox.height, 0.0);
    });

    testWidgets('adds bottom spacing for non-zero viewport height', (tester) async {
      final key = GlobalKey();
      await pumpContainer(tester, viewportHeight: 100, key: key);

      final sizedBox = tester.widget<SizedBox>(find.byKey(key));
      expect(sizedBox.height, 100 + bottomSpacing);
    });
  });

  group('AdyenComponentController integration', () {
    test('isReady and requiresUserInteraction start null/false', () {
      final controller = AdyenComponentController();
      expect(controller.isReady, false);
      expect(controller.requiresUserInteraction, isNull);
    });

    test('cannot submit before attached and ready', () {
      final controller = AdyenComponentController();
      expect(controller.submit, throwsStateError);
    });
  });
}
