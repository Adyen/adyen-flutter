import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/main_common.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/advanced_checkout_repository.dart';
import 'package:adyen_checkout_example/repositories/session_checkout_repository.dart';
import 'package:adyen_checkout_example/screens/component/advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/component_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/session_component_screen.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeService implements Service {
  @override
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body) async =>
      {};

  @override
  Future<Map<String, dynamic>> fetchPaymentMethods(
          Map<String, dynamic> body) async =>
      {};

  @override
  Future<Map<String, dynamic>> postPayments(Map<String, dynamic> body) async =>
      {};

  @override
  Future<Map<String, dynamic>> postPaymentsDetails(
          Map<String, dynamic> body) async =>
      {};

  @override
  Future<Map<String, dynamic>> postCardDetails(
          Map<String, dynamic> body) async =>
      {};
}

void main() {
  test('flow repositories build configuration directly from Config', () {
    final sessionConfiguration =
        SessionCheckoutRepository(service: FakeService()).buildConfiguration();
    final advancedConfiguration =
        AdvancedCheckoutRepository(service: FakeService()).buildConfiguration();

    expect(sessionConfiguration.amount?.currency, Config.amount.currency);
    expect(sessionConfiguration.amount?.value, Config.amount.value);
    expect(sessionConfiguration.countryCode, Config.countryCode);
    expect(sessionConfiguration.applePayConfiguration?.buttonWidth, 200);
    expect(sessionConfiguration.applePayConfiguration?.buttonHeight, 48);
    expect(
      sessionConfiguration.applePayConfiguration?.buttonStyle?.type,
      ApplePayButtonType.buy,
    );
    expect(advancedConfiguration.amount?.currency, Config.amount.currency);
    expect(advancedConfiguration.amount?.value, Config.amount.value);
    expect(advancedConfiguration.countryCode, Config.countryCode);
  });

  testWidgets(
      'shows the checkout integration choices and navigates to card navigation',
      (tester) async {
    await tester.pumpWidget(CheckoutExample(service: FakeService()));
    expect(find.text('Card component'), findsOneWidget);
    expect(find.text('Multi component'), findsOneWidget);

    await tester.tap(find.text('Card component'));
    await tester.pumpAndSettle();

    expect(find.text('Card component session'), findsOneWidget);
    expect(find.text('Card component advanced'), findsOneWidget);
    expect(find.text('Card component bottom sheet'), findsOneWidget);
  });

  testWidgets('generic component navigation passes flat screen parameters',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComponentNavigationScreen(
          sessionRepository: SessionCheckoutRepository(service: FakeService()),
          advancedRepository:
              AdvancedCheckoutRepository(service: FakeService()),
          title: 'BLIK',
          txVariant: 'blik',
        ),
      ),
    );

    expect(find.text('BLIK component'), findsOneWidget);
    expect(find.text('BLIK component session'), findsOneWidget);
    expect(find.text('BLIK component advanced'), findsOneWidget);

    await tester.tap(find.text('BLIK component session'));
    await tester.pumpAndSettle();

    final screen = tester.widget<SessionComponentScreen>(
      find.byType(SessionComponentScreen),
    );
    expect(screen.title, 'BLIK');
    expect(screen.txVariant, 'blik');
  });

  testWidgets('generic navigation passes parameters to advanced screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ComponentNavigationScreen(
          sessionRepository: SessionCheckoutRepository(service: FakeService()),
          advancedRepository:
              AdvancedCheckoutRepository(service: FakeService()),
          title: 'Google Pay',
          txVariant: 'googlepay',
        ),
      ),
    );

    await tester.tap(find.text('Google Pay component advanced'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final screen = tester.widget<AdvancedComponentScreen>(
      find.byType(AdvancedComponentScreen),
    );
    expect(screen.title, 'Google Pay');
    expect(screen.txVariant, 'googlepay');
  });

  testWidgets('navigates to multi component navigation', (tester) async {
    await tester.pumpWidget(CheckoutExample(service: FakeService()));

    await tester.tap(find.text('Multi component'));
    await tester.pumpAndSettle();

    expect(find.text('Multi component session'), findsOneWidget);
    expect(find.text('Multi component advanced'), findsOneWidget);
  });

  testWidgets('navigates to custom card screen', (tester) async {
    await tester.pumpWidget(CheckoutExample(service: FakeService()));

    expect(find.text('Custom card (CSE)'), findsOneWidget);
    await tester.tap(find.text('Custom card (CSE)'));
    await tester.pumpAndSettle();

    expect(find.text('Adyen custom card'), findsOneWidget);
    expect(find.text('Card number'), findsOneWidget);
    expect(find.text('Expiry date'), findsOneWidget);
    expect(find.text('Security code'), findsOneWidget);
    expect(find.text('PAY'), findsOneWidget);
  });

  testWidgets(
      'closing result dialog navigates back like pop when popOnDismiss is true',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (detailContext) => Scaffold(
                        appBar: AppBar(title: const Text('Detail Screen')),
                        body: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              DialogBuilder.showPaymentResultDialog(
                                'Payment Result',
                                'Result code: Authorised',
                                detailContext,
                              );
                            },
                            child: const Text('Show Result'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Detail'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Screen'), findsOneWidget);

    await tester.tap(find.text('Show Result'));
    await tester.pumpAndSettle();
    expect(find.text('Payment Result'), findsOneWidget);
    expect(find.text('Result code: Authorised'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Result'), findsNothing);
    expect(find.text('Detail Screen'), findsNothing);
    expect(find.text('Open Detail'), findsOneWidget);
  });

  testWidgets('closing dialog does not pop screen when popOnDismiss is false',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (detailContext) => Scaffold(
                        appBar: AppBar(title: const Text('Detail Screen')),
                        body: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              DialogBuilder.showPaymentResultDialog(
                                'Action Error',
                                'Error details',
                                detailContext,
                                popOnDismiss: false,
                              );
                            },
                            child: const Text('Show Error'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open Detail'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Screen'), findsOneWidget);

    await tester.tap(find.text('Show Error'));
    await tester.pumpAndSettle();
    expect(find.text('Action Error'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Action Error'), findsNothing);
    expect(find.text('Detail Screen'), findsOneWidget);
  });
}
