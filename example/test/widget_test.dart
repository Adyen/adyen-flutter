import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/main_common.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/advanced_checkout_repository.dart';
import 'package:adyen_checkout_example/repositories/session_checkout_repository.dart';
import 'package:adyen_checkout_example/screens/component/advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/component_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/component_submit_button.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_component_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_payment_methods.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_session_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/session_component_screen.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestCheckoutController extends CheckoutController {
  bool _isReady = false;
  bool? _requiresUserInteraction;
  int submitCount = 0;

  @override
  bool get isReady => _isReady;

  @override
  bool? get requiresUserInteraction => _requiresUserInteraction;

  void setReady({required bool requiresUserInteraction}) {
    _isReady = true;
    _requiresUserInteraction = requiresUserInteraction;
    notifyListeners();
  }

  @override
  Future<void> submit() async => submitCount++;
}

class CapturingSessionCheckoutRepository extends SessionCheckoutRepository {
  final Completer<SessionCheckout> _setupCompleter =
      Completer<SessionCheckout>();
  late SessionCheckoutCallbacks callbacks;

  CapturingSessionCheckoutRepository() : super(service: FakeService());

  @override
  Future<SessionCheckout> setupCheckout({
    required SessionCheckoutCallbacks callbacks,
  }) {
    this.callbacks = callbacks;
    return _setupCompleter.future;
  }
}

class CapturingAdvancedCheckoutRepository extends AdvancedCheckoutRepository {
  final Completer<AdvancedCheckout> _setupCompleter =
      Completer<AdvancedCheckout>();
  late AdvancedCheckoutCallbacks callbacks;

  CapturingAdvancedCheckoutRepository() : super(service: FakeService());

  @override
  Future<AdvancedCheckout> setupCheckout({
    required AdvancedCheckoutCallbacks callbacks,
  }) {
    this.callbacks = callbacks;
    return _setupCompleter.future;
  }
}

class RecordingService extends FakeService {
  Map<String, dynamic>? sessionRequest;
  Map<String, dynamic>? paymentsRequest;

  @override
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body) async {
    sessionRequest = body;
    return {'id': 'session-id', 'sessionData': 'session-data'};
  }

  @override
  Future<Map<String, dynamic>> postPayments(Map<String, dynamic> body) async {
    paymentsRequest = body;
    return {'resultCode': 'Authorised'};
  }
}

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

  test('instant screens resolve the full v1 payment method set in order', () {
    final paymentMethods = [
      PaymentMethod(type: 'twint', name: 'TWINT'),
      PaymentMethod(type: 'scheme', name: 'Card'),
      PaymentMethod(type: 'paybybank', name: 'Pay by Bank'),
      PaymentMethod(type: 'ideal', name: 'iDEAL'),
      PaymentMethod(type: 'klarna', name: 'Klarna'),
      PaymentMethod(type: 'paypal', name: 'PayPal'),
    ];

    expect(
      resolveInstantPaymentMethods(paymentMethods).map((method) => method.type),
      ['ideal', 'paypal', 'klarna', 'paybybank', 'twint'],
    );
  });

  test('repositories use the registered platform return URLs', () {
    final sessionRepository = SessionCheckoutRepository(service: FakeService());
    final advancedRepository =
        AdvancedCheckoutRepository(service: FakeService());

    expect(
      sessionRepository.determineReturnUrl(platform: TargetPlatform.android),
      'adyencheckout://com.adyen.adyen_checkout_example/adyenPayment',
    );
    expect(
      advancedRepository.determineReturnUrl(platform: TargetPlatform.android),
      'adyencheckout://com.adyen.adyen_checkout_example/adyenPayment',
    );
    expect(
      sessionRepository.determineReturnUrl(platform: TargetPlatform.iOS),
      'com.mydomain.adyencheckout://adyenPayment',
    );
    expect(
      advancedRepository.determineReturnUrl(platform: TargetPlatform.iOS),
      'com.mydomain.adyencheckout://adyenPayment',
    );
  });

  test('Session and Advanced requests include matching line items', () async {
    final service = RecordingService();
    final sessionRepository = SessionCheckoutRepository(service: service);
    final advancedRepository = AdvancedCheckoutRepository(service: service);

    await sessionRepository.createSessionResponse();
    await advancedRepository.onSubmit(PaymentComponentData(data: const {}));

    for (final request in [service.sessionRequest, service.paymentsRequest]) {
      final lineItems = request?['lineItems'] as List<dynamic>;
      expect(lineItems, hasLength(1));
      final lineItem = lineItems.single as Map<String, dynamic>;
      expect(lineItem['quantity'], 1);
      expect(lineItem['amountExcludingTax'], Config.amount.value);
      expect(lineItem['taxPercentage'], 0);
      expect(lineItem['taxAmount'], 0);
      expect(lineItem['amountIncludingTax'], Config.amount.value);
      expect(lineItem['description'], 'Shoes');
      expect(lineItem['id'], 'Item #1');
    }
  });

  testWidgets('Instant Session shows browser cancellation as a failure result',
      (tester) async {
    final repository = CapturingSessionCheckoutRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: InstantSessionComponentScreen(repository: repository),
      ),
    );

    repository.callbacks.onFailure(
      const CheckoutError(
        code: CheckoutError.cancellationCode,
        message: 'Payment cancelled.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Payment Failed'), findsOneWidget);
    expect(find.text('Cancelled: Payment cancelled.'), findsOneWidget);
  });

  testWidgets('Instant Advanced shows browser cancellation as a failure result',
      (tester) async {
    final repository = CapturingAdvancedCheckoutRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: InstantAdvancedComponentScreen(repository: repository),
      ),
    );

    repository.callbacks.onFailure(
      const CheckoutError(
        code: CheckoutError.cancellationCode,
        message: 'Payment cancelled.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Payment Failed'), findsOneWidget);
    expect(find.text('Cancelled: Payment cancelled.'), findsOneWidget);
  });

  testWidgets('missing component shows an explicit unavailable state',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ComponentUnavailableMessage(paymentMethodName: 'PayPal'),
        ),
      ),
    );

    expect(find.text('PayPal is not available.'), findsOneWidget);
  });

  testWidgets('direct component shows one-shot controller submit button',
      (tester) async {
    final controller = TestCheckoutController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComponentSubmitButton(
            controller: controller,
            paymentMethodName: 'iDEAL',
          ),
        ),
      ),
    );

    expect(find.text('Pay with iDEAL'), findsNothing);

    controller.setReady(requiresUserInteraction: true);
    await tester.pump();
    expect(find.text('Pay with iDEAL'), findsNothing);

    controller.setReady(requiresUserInteraction: false);
    await tester.pump();
    expect(find.text('Pay with iDEAL'), findsOneWidget);

    await tester.tap(find.text('Pay with iDEAL'));
    await tester.pump();
    expect(controller.submitCount, 1);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
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

  testWidgets('navigates to the instant flow choices', (tester) async {
    await tester.pumpWidget(CheckoutExample(service: FakeService()));

    expect(find.text('Instant component'), findsOneWidget);
    await tester.tap(find.text('Instant component'));
    await tester.pumpAndSettle();

    expect(find.text('Instant component session'), findsOneWidget);
    expect(find.text('Instant component advanced'), findsOneWidget);
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

  testWidgets('instant navigation opens the dedicated session screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InstantComponentNavigationScreen(
          sessionRepository: SessionCheckoutRepository(service: FakeService()),
          advancedRepository:
              AdvancedCheckoutRepository(service: FakeService()),
        ),
      ),
    );

    expect(find.text('Instant component session'), findsOneWidget);
    expect(find.text('Instant component advanced'), findsOneWidget);
    expect(find.text('iDEAL component session'), findsNothing);

    await tester.tap(find.text('Instant component session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(InstantSessionComponentScreen), findsOneWidget);
  });

  testWidgets('instant navigation opens the dedicated advanced screen',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InstantComponentNavigationScreen(
          sessionRepository: SessionCheckoutRepository(service: FakeService()),
          advancedRepository:
              AdvancedCheckoutRepository(service: FakeService()),
        ),
      ),
    );

    await tester.tap(find.text('Instant component advanced'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(InstantAdvancedComponentScreen), findsOneWidget);
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
