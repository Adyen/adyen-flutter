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

  setUp(() {
    rootBundle.clear();
    mockPigeonChannel(
      ComponentChannels.availability,
      respond: (_) => <Object?>[
        InstantPaymentSetupResultDTO(
          instantPaymentType: InstantPaymentType.applePay,
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

  testWidgets('routes onSubmit to the checkout from the current widget', (
    tester,
  ) async {
    // given a component rebuilt with a different AdvancedCheckout
    var firstCheckoutSubmitCount = 0;
    var secondCheckoutSubmitCount = 0;
    final firstCheckout = _checkout(() => firstCheckoutSubmitCount++);
    final secondCheckout = _checkout(() => secondCheckoutSubmitCount++);
    await tester.pumpWidget(_app(firstCheckout));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(secondCheckout));
    await tester.pumpAndSettle();

    // when native sends an onSubmit event
    ComponentFlutterApi.instance.onComponentCommunication(
      ComponentCommunicationModel(
        type: ComponentCommunicationType.onSubmit,
        componentId: 'APPLE_PAY_ADVANCED_COMPONENT',
        data: jsonEncode({
          'data': <String, dynamic>{'paymentMethod': 'applepay'},
          'extra': <String, dynamic>{},
        }),
      ),
    );
    await tester.pumpAndSettle();

    // then the checkout of the current widget handles it
    expect(firstCheckoutSubmitCount, 0);
    expect(secondCheckoutSubmitCount, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets(
      'switching from checkout A to B before paying submits with checkout B', (
    tester,
  ) async {
    final pressedMessages = <List<Object?>>[];
    final paymentsResultMessages = <List<Object?>>[];
    mockPigeonChannel(
      ComponentChannels.instantPaymentPressed,
      capturedMessages: pressedMessages,
    );
    mockPigeonChannel(
      ComponentChannels.paymentsResult,
      capturedMessages: paymentsResultMessages,
    );
    addTearDown(
        () => unmockPigeonChannel(ComponentChannels.instantPaymentPressed));
    // given a screen showing checkout A, switched to checkout B
    final submittedBy = <String>[];
    await tester.pumpWidget(
      MaterialApp(home: _SwitchCheckoutScreen(onSubmitted: submittedBy.add)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use B'));
    await tester.pumpAndSettle();

    // when the shopper taps the Apple Pay button
    tester
        .widget<pay_sdk.RawApplePayButton>(
          find.byType(pay_sdk.RawApplePayButton),
        )
        .onPressed!
        .call();
    await tester.pumpAndSettle();

    // then the sheet is configured with checkout B's amount
    expect(pressedMessages, hasLength(1));
    final sheetConfiguration =
        pressedMessages.single[0]! as InstantPaymentConfigurationDTO;
    final componentId = pressedMessages.single[2]! as String;
    expect(sheetConfiguration.amount?.value, 2500);

    // when native sends the onSubmit event
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      ComponentChannels.componentCommunication,
      ComponentFlutterInterface.pigeonChannelCodec.encodeMessage(<Object?>[
        ComponentCommunicationModel(
          type: ComponentCommunicationType.onSubmit,
          componentId: componentId,
          data: jsonEncode({
            'data': <String, dynamic>{'paymentMethod': 'applepay'},
            'extra': <String, dynamic>{},
          }),
        ),
      ]),
      (_) {},
    );
    await tester.pumpAndSettle();

    // then checkout B handles it and native receives B's result
    expect(submittedBy, ['B']);
    expect(paymentsResultMessages, hasLength(1));
    final paymentEvent = paymentsResultMessages.single[1]! as PaymentEventDTO;
    expect(paymentEvent.result, 'Authorised-B');
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('routes result events to the current widget', (tester) async {
    // given a component rebuilt with a different onPaymentResult callback
    final resultsA = <PaymentResult>[];
    final resultsB = <PaymentResult>[];
    final checkout = _checkout(() {});
    await tester.pumpWidget(_app(checkout, onPaymentResult: resultsA.add));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(checkout, onPaymentResult: resultsB.add));
    await tester.pumpAndSettle();

    // when native sends a result event
    ComponentFlutterApi.instance.onComponentCommunication(
      _resultEvent(),
    );
    await tester.pumpAndSettle();

    // then only the callback of the current widget is called
    expect(resultsA, isEmpty);
    expect(resultsB.single, isA<PaymentAdvancedFinished>());
    expect(
      (resultsB.single as PaymentAdvancedFinished).resultCode,
      ResultCode.authorised,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('session flow routes result events to the current widget', (
    tester,
  ) async {
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
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _app(sessionCheckout, onPaymentResult: resultsB.add),
    );
    await tester.pumpAndSettle();

    // when native sends a result event
    ComponentFlutterApi.instance.onComponentCommunication(
      _resultEvent(componentId: 'APPLE_PAY_SESSION_COMPONENT'),
    );
    await tester.pumpAndSettle();

    // then only the callback of the current widget is called
    expect(resultsA, isEmpty);
    expect(resultsB.single, isA<PaymentSessionFinished>());
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('sends the payment result to native without a rebuild', (
    tester,
  ) async {
    // given a mounted component
    final paymentsResultMessages = <List<Object?>>[];
    mockPigeonChannel(
      ComponentChannels.paymentsResult,
      capturedMessages: paymentsResultMessages,
    );
    var submitCount = 0;
    await tester.pumpWidget(_app(_checkout(() => submitCount++)));
    await tester.pumpAndSettle();

    // when native sends an onSubmit event
    ComponentFlutterApi.instance.onComponentCommunication(_submitEvent());
    await tester.pumpAndSettle();

    // then the checkout handles it once and native receives the result
    expect(submitCount, 1);
    expect(paymentsResultMessages, hasLength(1));
    expect(
      paymentsResultMessages.single[0],
      'APPLE_PAY_ADVANCED_COMPONENT',
    );
    final paymentEvent = paymentsResultMessages.single[1]! as PaymentEventDTO;
    expect(paymentEvent.paymentEventType, PaymentEventType.finished);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('sends an error to native when onSubmit throws', (tester) async {
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
    await tester.pumpAndSettle();

    // when native sends an onSubmit event
    ComponentFlutterApi.instance.onComponentCommunication(_submitEvent());
    await tester.pumpAndSettle();

    // then native receives an error with the failure reason
    expect(paymentsResultMessages, hasLength(1));
    final paymentEvent = paymentsResultMessages.single[1]! as PaymentEventDTO;
    expect(paymentEvent.paymentEventType, PaymentEventType.error);
    expect(paymentEvent.error?.errorMessage, contains('submit failed'));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('ignores events for another componentId', (tester) async {
    // given a mounted component
    var submitCount = 0;
    await tester.pumpWidget(_app(_checkout(() => submitCount++)));
    await tester.pumpAndSettle();

    // when native sends an event for a different component
    ComponentFlutterApi.instance.onComponentCommunication(
      _submitEvent(componentId: 'OTHER_COMPONENT'),
    );
    await tester.pumpAndSettle();

    // then the checkout is not called
    expect(submitCount, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('keeps the loading indicator across a rebuild', (tester) async {
    // given a mounted component that received a loading event
    final checkout = _checkout(() {});
    await tester.pumpWidget(
      _app(checkout, loadingIndicator: const Text('loading')),
    );
    await tester.pumpAndSettle();
    ComponentFlutterApi.instance.onComponentCommunication(
      _event(ComponentCommunicationType.loading),
    );
    await tester.pumpAndSettle();
    expect(find.text('loading'), findsOneWidget);

    // when the component is rebuilt with a new widget
    await tester.pumpWidget(
      _app(
        _checkout(() {}),
        loadingIndicator: const Text('loading'),
      ),
    );
    await tester.pumpAndSettle();

    // then the loading indicator is still shown
    expect(find.text('loading'), findsOneWidget);
    expect(find.byType(pay_sdk.RawApplePayButton), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('keeps the button locked across a rebuild', (tester) async {
    // given a mounted component whose button was pressed
    final checkout = _checkout(() {});
    await tester.pumpWidget(_app(checkout));
    await tester.pumpAndSettle();
    tester
        .widget<pay_sdk.RawApplePayButton>(
          find.byType(pay_sdk.RawApplePayButton),
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
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('shows the button again after a result event', (tester) async {
    // given a mounted component that received a loading event
    await tester.pumpWidget(
      _app(_checkout(() {}), loadingIndicator: const Text('loading')),
    );
    await tester.pumpAndSettle();
    ComponentFlutterApi.instance.onComponentCommunication(
      _event(ComponentCommunicationType.loading),
    );
    await tester.pumpAndSettle();
    expect(find.text('loading'), findsOneWidget);

    // when native sends a result event
    ComponentFlutterApi.instance.onComponentCommunication(_resultEvent());
    await tester.pumpAndSettle();

    // then the button is shown again and is clickable
    expect(find.text('loading'), findsNothing);
    expect(find.byType(pay_sdk.RawApplePayButton), findsOneWidget);
    expect(
      tester.widgetList<IgnorePointer>(_buttonLock).first.ignoring,
      isFalse,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('disposes cleanly after several rebuilds', (tester) async {
    // given a component that was rebuilt several times
    await tester.pumpWidget(_app(_checkout(() {})));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(_checkout(() {})));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(_checkout(() {})));
    await tester.pumpAndSettle();

    // when the component is removed from the tree
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    // then no exception is thrown
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}

Finder get _buttonLock => find.ancestor(
      of: find.byType(pay_sdk.RawApplePayButton),
      matching: find.byType(IgnorePointer),
    );

ComponentCommunicationModel _event(
  ComponentCommunicationType type, {
  String componentId = 'APPLE_PAY_ADVANCED_COMPONENT',
  Object? data,
  PaymentResultDTO? paymentResult,
}) =>
    ComponentCommunicationModel(
      type: type,
      componentId: componentId,
      data: data,
      paymentResult: paymentResult,
    );

ComponentCommunicationModel _submitEvent({
  String componentId = 'APPLE_PAY_ADVANCED_COMPONENT',
}) =>
    _event(
      ComponentCommunicationType.onSubmit,
      componentId: componentId,
      data: jsonEncode({
        'data': <String, dynamic>{'paymentMethod': 'applepay'},
        'extra': <String, dynamic>{},
      }),
    );

ComponentCommunicationModel _resultEvent({
  String componentId = 'APPLE_PAY_ADVANCED_COMPONENT',
}) =>
    _event(
      ComponentCommunicationType.result,
      componentId: componentId,
      paymentResult: PaymentResultDTO(
        type: PaymentResultEnum.finished,
        result: PaymentResultModelDTO(resultCode: 'authorised'),
      ),
    );

class _SwitchCheckoutScreen extends StatefulWidget {
  const _SwitchCheckoutScreen({required this.onSubmitted});

  final ValueChanged<String> onSubmitted;

  @override
  State<_SwitchCheckoutScreen> createState() => _SwitchCheckoutScreenState();
}

class _SwitchCheckoutScreenState extends State<_SwitchCheckoutScreen> {
  late final AdvancedCheckout _checkoutA = _switchCheckout('A');
  late final AdvancedCheckout _checkoutB = _switchCheckout('B');
  late final ApplePayComponentConfiguration _configurationA =
      _switchConfiguration(1000);
  late final ApplePayComponentConfiguration _configurationB =
      _switchConfiguration(2500);
  late AdvancedCheckout _currentCheckout = _checkoutA;
  late ApplePayComponentConfiguration _currentConfiguration = _configurationA;

  AdvancedCheckout _switchCheckout(String label) => AdvancedCheckout(
        onSubmit: (data, [extra]) async {
          widget.onSubmitted(label);
          return Finished(resultCode: 'Authorised-$label');
        },
        onAdditionalDetails: (_) async => Finished(resultCode: 'Authorised'),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            TextButton(
              onPressed: () => setState(() {
                _currentCheckout = _checkoutA;
                _currentConfiguration = _configurationA;
              }),
              child: const Text('Use A'),
            ),
            TextButton(
              onPressed: () => setState(() {
                _currentCheckout = _checkoutB;
                _currentConfiguration = _configurationB;
              }),
              child: const Text('Use B'),
            ),
            AdyenApplePayComponent(
              configuration: _currentConfiguration,
              paymentMethod: const <String, dynamic>{'type': 'applepay'},
              checkout: _currentCheckout,
              onPaymentResult: (_) {},
            ),
          ],
        ),
      );
}

ApplePayComponentConfiguration _switchConfiguration(int amount) =>
    ApplePayComponentConfiguration(
      environment: Environment.test,
      clientKey: 'test_client_key',
      countryCode: 'NL',
      amount: Amount(value: amount, currency: 'EUR'),
      applePayConfiguration: ApplePayConfiguration(
        merchantId: 'merchant.com.adyen.test',
        merchantName: 'Test merchant',
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
        body: AdyenApplePayComponent(
          configuration: ApplePayComponentConfiguration(
            environment: Environment.test,
            clientKey: 'test_client_key',
            countryCode: 'NL',
            amount: Amount(value: 1000, currency: 'EUR'),
            applePayConfiguration: ApplePayConfiguration(
              merchantId: 'merchant.com.adyen.test',
              merchantName: 'Test merchant',
            ),
          ),
          paymentMethod: const <String, dynamic>{'type': 'applepay'},
          checkout: checkout,
          onPaymentResult: onPaymentResult ?? (_) {},
          loadingIndicator: loadingIndicator,
        ),
      ),
    );
