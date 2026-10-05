import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/components/component_flutter_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pay/pay.dart' as pay_sdk;

import 'utils/component_channel_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const advancedComponentId = 'GOOGLE_PAY_ADVANCED_COMPONENT';
  const sessionComponentId = 'GOOGLE_PAY_SESSION_COMPONENT';

  setUp(() {
    rootBundle.clear();
    mockPigeonChannel(
      ComponentChannels.availability,
      respond: (_) => <Object?>[
        InstantPaymentSetupResultDTO(
          instantPaymentType: InstantPaymentType.googlePay,
          isSupported: true,
        ),
      ],
    );
    mockPigeonChannel(ComponentChannels.paymentsResult);
    mockPigeonChannel(ComponentChannels.dispose);
  });

  tearDown(() {
    unmockPigeonChannel(ComponentChannels.availability);
    unmockPigeonChannel(ComponentChannels.paymentsResult);
    unmockPigeonChannel(ComponentChannels.dispose);
  });

  testWidgets(
    'routes onSubmit to the checkout from the current widget',
    (tester) async {
      // given a component rebuilt with a different AdvancedCheckout
      var firstCheckoutSubmitCount = 0;
      var secondCheckoutSubmitCount = 0;
      final firstCheckout = _checkout(() => firstCheckoutSubmitCount++);
      final secondCheckout = _checkout(() => secondCheckoutSubmitCount++);
      await tester.pumpWidget(_app(firstCheckout));
      await _makeAvailable(tester, advancedComponentId);
      await tester.pumpWidget(_app(secondCheckout));
      await tester.pumpAndSettle();

      // when native sends an onSubmit event
      ComponentFlutterApi.instance.onComponentCommunication(
        _submitEvent(componentId: advancedComponentId),
      );
      await tester.pumpAndSettle();

      // then the checkout of the current widget handles it
      expect(firstCheckoutSubmitCount, 0);
      expect(secondCheckoutSubmitCount, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'routes result events to the current widget',
    (tester) async {
      // given a component rebuilt with a different onPaymentResult callback
      final resultsA = <PaymentResult>[];
      final resultsB = <PaymentResult>[];
      final checkout = _checkout(() {});
      await tester.pumpWidget(_app(checkout, onPaymentResult: resultsA.add));
      await _makeAvailable(tester, advancedComponentId);
      await tester.pumpWidget(_app(checkout, onPaymentResult: resultsB.add));
      await tester.pumpAndSettle();

      // when native sends a result event
      ComponentFlutterApi.instance.onComponentCommunication(
        _resultEvent(componentId: advancedComponentId),
      );
      await tester.pumpAndSettle();

      // then only the callback of the current widget is called
      expect(resultsA, isEmpty);
      expect(resultsB.single, isA<PaymentAdvancedFinished>());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'session flow routes result events to the current widget',
    (tester) async {
      // given a session component rebuilt with a different onPaymentResult
      final resultsA = <PaymentResult>[];
      final resultsB = <PaymentResult>[];
      final sessionCheckout = SessionCheckout(
        id: 'session_id',
        sessionData: 'session_data',
        paymentMethods: const <String, dynamic>{},
      );
      await tester.pumpWidget(
        _app(sessionCheckout, onPaymentResult: resultsA.add),
      );
      await _makeAvailable(tester, sessionComponentId);
      await tester.pumpWidget(
        _app(sessionCheckout, onPaymentResult: resultsB.add),
      );
      await tester.pumpAndSettle();

      // when native sends a result event
      ComponentFlutterApi.instance.onComponentCommunication(
        _resultEvent(componentId: sessionComponentId),
      );
      await tester.pumpAndSettle();

      // then only the callback of the current widget is called
      expect(resultsA, isEmpty);
      expect(resultsB.single, isA<PaymentSessionFinished>());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'sends the payment result to native without a rebuild',
    (tester) async {
      // given a mounted component
      final paymentsResultMessages = <List<Object?>>[];
      mockPigeonChannel(
        ComponentChannels.paymentsResult,
        capturedMessages: paymentsResultMessages,
      );
      var submitCount = 0;
      await tester.pumpWidget(_app(_checkout(() => submitCount++)));
      await _makeAvailable(tester, advancedComponentId);

      // when native sends an onSubmit event
      ComponentFlutterApi.instance.onComponentCommunication(
        _submitEvent(componentId: advancedComponentId),
      );
      await tester.pumpAndSettle();

      // then the checkout handles it once and native receives the result
      expect(submitCount, 1);
      expect(paymentsResultMessages, hasLength(1));
      expect(paymentsResultMessages.single[0], advancedComponentId);
      final paymentEvent = paymentsResultMessages.single[1]! as PaymentEventDTO;
      expect(paymentEvent.paymentEventType, PaymentEventType.finished);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'sends an error to native when onSubmit throws',
    (tester) async {
      // given a mounted component whose onSubmit fails
      final paymentsResultMessages = <List<Object?>>[];
      mockPigeonChannel(
        ComponentChannels.paymentsResult,
        capturedMessages: paymentsResultMessages,
      );
      final failingCheckout = AdvancedCheckout(
        onSubmit: (data, [extra]) async => throw Exception('submit failed'),
        onAdditionalDetails: (_) async => Finished(resultCode: 'Authorised'),
      );
      await tester.pumpWidget(_app(failingCheckout));
      await _makeAvailable(tester, advancedComponentId);

      // when native sends an onSubmit event
      ComponentFlutterApi.instance.onComponentCommunication(
        _submitEvent(componentId: advancedComponentId),
      );
      await tester.pumpAndSettle();

      // then native receives an error with the failure reason
      expect(paymentsResultMessages, hasLength(1));
      final paymentEvent = paymentsResultMessages.single[1]! as PaymentEventDTO;
      expect(paymentEvent.paymentEventType, PaymentEventType.error);
      expect(paymentEvent.error?.errorMessage, contains('submit failed'));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'ignores events for another componentId',
    (tester) async {
      // given a mounted component
      var submitCount = 0;
      await tester.pumpWidget(_app(_checkout(() => submitCount++)));
      await _makeAvailable(tester, advancedComponentId);

      // when native sends an event for a different component
      ComponentFlutterApi.instance.onComponentCommunication(
        _submitEvent(componentId: 'OTHER_COMPONENT'),
      );
      await tester.pumpAndSettle();

      // then the checkout is not called
      expect(submitCount, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'keeps the loading indicator across a rebuild',
    (tester) async {
      // given a mounted component that received a loading event
      await tester.pumpWidget(
        _app(_checkout(() {}), loadingIndicator: const Text('loading')),
      );
      await _makeAvailable(tester, advancedComponentId);
      ComponentFlutterApi.instance.onComponentCommunication(
        _event(
          ComponentCommunicationType.loading,
          componentId: advancedComponentId,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('loading'), findsOneWidget);

      // when the component is rebuilt with a new widget
      await tester.pumpWidget(
        _app(_checkout(() {}), loadingIndicator: const Text('loading')),
      );
      await tester.pumpAndSettle();

      // then the loading indicator is still shown
      expect(find.text('loading'), findsOneWidget);
      expect(find.byType(pay_sdk.RawGooglePayButton), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'keeps the button locked across a rebuild',
    (tester) async {
      // given a mounted component whose button was pressed
      await tester.pumpWidget(_app(_checkout(() {})));
      await _makeAvailable(tester, advancedComponentId);
      tester
          .widget<pay_sdk.RawGooglePayButton>(
            find.byType(pay_sdk.RawGooglePayButton),
          )
          .onPressed!
          .call();
      await tester.pumpAndSettle();
      expect(
        tester.widgetList<IgnorePointer>(_buttonLock).first.ignoring,
        isTrue,
      );

      // when the component is rebuilt with a new widget
      await tester.pumpWidget(_app(_checkout(() {})));
      await tester.pumpAndSettle();

      // then the button is still locked
      expect(
        tester.widgetList<IgnorePointer>(_buttonLock).first.ignoring,
        isTrue,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'shows the button again after a result event',
    (tester) async {
      // given a mounted component that received a loading event
      await tester.pumpWidget(
        _app(_checkout(() {}), loadingIndicator: const Text('loading')),
      );
      await _makeAvailable(tester, advancedComponentId);
      ComponentFlutterApi.instance.onComponentCommunication(
        _event(
          ComponentCommunicationType.loading,
          componentId: advancedComponentId,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('loading'), findsOneWidget);

      // when native sends a result event
      ComponentFlutterApi.instance.onComponentCommunication(
        _resultEvent(componentId: advancedComponentId),
      );
      await tester.pumpAndSettle();

      // then the button is shown again and is clickable
      expect(find.text('loading'), findsNothing);
      expect(find.byType(pay_sdk.RawGooglePayButton), findsOneWidget);
      expect(
        tester.widgetList<IgnorePointer>(_buttonLock).first.ignoring,
        isFalse,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'disposes cleanly after several rebuilds',
    (tester) async {
      // given a component that was rebuilt several times
      await tester.pumpWidget(_app(_checkout(() {})));
      await _makeAvailable(tester, advancedComponentId);
      await tester.pumpWidget(_app(_checkout(() {})));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(_checkout(() {})));
      await tester.pumpAndSettle();

      // when the component is removed from the tree
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      // then no exception is thrown
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

Future<void> _makeAvailable(WidgetTester tester, String componentId) async {
  ComponentFlutterApi.instance.onComponentCommunication(
    ComponentCommunicationModel(
      type: ComponentCommunicationType.availability,
      componentId: componentId,
      data: InstantPaymentSetupResultDTO(
        instantPaymentType: InstantPaymentType.googlePay,
        isSupported: true,
        resultData: const <Object?>[],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _buttonLock => find.ancestor(
      of: find.byType(pay_sdk.RawGooglePayButton),
      matching: find.byType(IgnorePointer),
    );

ComponentCommunicationModel _event(
  ComponentCommunicationType type, {
  required String componentId,
  Object? data,
  PaymentResultDTO? paymentResult,
}) =>
    ComponentCommunicationModel(
      type: type,
      componentId: componentId,
      data: data,
      paymentResult: paymentResult,
    );

ComponentCommunicationModel _submitEvent({required String componentId}) =>
    _event(
      ComponentCommunicationType.onSubmit,
      componentId: componentId,
      data: jsonEncode({
        'data': <String, dynamic>{'paymentMethod': 'googlepay'},
        'extra': <String, dynamic>{},
      }),
    );

ComponentCommunicationModel _resultEvent({required String componentId}) =>
    _event(
      ComponentCommunicationType.result,
      componentId: componentId,
      paymentResult: PaymentResultDTO(
        type: PaymentResultEnum.finished,
        result: PaymentResultModelDTO(resultCode: 'authorised'),
      ),
    );

AdvancedCheckout _checkout(VoidCallback onSubmit) => AdvancedCheckout(
      onSubmit: (data, [extra]) async {
        onSubmit();
        return Finished(resultCode: 'Authorised');
      },
      onAdditionalDetails: (_) async => Finished(resultCode: 'Authorised'),
    );

Widget _app(
  Checkout checkout, {
  Function(PaymentResult)? onPaymentResult,
  Widget? loadingIndicator,
}) =>
    MaterialApp(
      home: Scaffold(
        body: AdyenGooglePayComponent(
          configuration: GooglePayComponentConfiguration(
            environment: Environment.test,
            clientKey: 'test_client_key',
            countryCode: 'NL',
            amount: Amount(value: 1000, currency: 'EUR'),
            googlePayConfiguration: GooglePayConfiguration(
              googlePayEnvironment: GooglePayEnvironment.test,
            ),
          ),
          paymentMethod: const <String, dynamic>{'type': 'googlepay'},
          checkout: checkout,
          onPaymentResult: onPaymentResult ?? (_) {},
          loadingIndicator: loadingIndicator,
        ),
      ),
    );
