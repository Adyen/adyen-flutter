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
      respond: (message) {
        final availability = InstantPaymentSetupResultDTO(
          instantPaymentType: InstantPaymentType.googlePay,
          isSupported: true,
          resultData: '[]',
        );
        ComponentFlutterApi.instance.onComponentCommunication(
          ComponentCommunicationModel(
            type: ComponentCommunicationType.availability,
            componentId: message[2] as String,
            data: availability,
          ),
        );
        return <Object?>[availability];
      },
    );
    mockPigeonChannel(ComponentChannels.instantPaymentPressed);
    mockPigeonChannel(ComponentChannels.dispose);
  });

  tearDown(() {
    unmockPigeonChannel(ComponentChannels.availability);
    unmockPigeonChannel(ComponentChannels.instantPaymentPressed);
    unmockPigeonChannel(ComponentChannels.dispose);
  });

  for (final session in [false, true]) {
    final flow = session ? 'session' : 'advanced';
    final componentId = session
        ? 'GOOGLE_PAY_SESSION_COMPONENT'
        : 'GOOGLE_PAY_ADVANCED_COMPONENT';

    testWidgets('$flow reuses and disposes both notifiers after rebuilds', (
      tester,
    ) async {
      final disposals = <List<Object?>>[];
      mockPigeonChannel(ComponentChannels.dispose, capturedMessages: disposals);
      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      final notifiers = _notifiers(tester);
      expect(notifiers, hasLength(2));

      for (var i = 0; i < 3; i++) {
        await tester.pumpWidget(_app(session));
        await tester.pumpAndSettle();
        final current = _notifiers(tester);
        expect(current, hasLength(2));
        for (var j = 0; j < notifiers.length; j++) {
          expect(current[j], same(notifiers[j]));
        }
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(disposals, [
        <Object?>[componentId]
      ]);
      for (final notifier in notifiers) {
        expect(() => notifier.addListener(() {}), throwsFlutterError);
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('$flow preserves loading across rebuilds until a result', (
      tester,
    ) async {
      final results = <PaymentResult>[];
      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      _sendEvent(ComponentCommunicationType.loading, componentId);
      await tester.pumpAndSettle();
      expect(find.text('loading'), findsOneWidget);

      await tester.pumpWidget(_app(session, onPaymentResult: results.add));
      await tester.pumpAndSettle();
      expect(find.text('loading'), findsOneWidget);
      expect(find.byType(pay_sdk.RawGooglePayButton), findsNothing);

      _sendEvent(ComponentCommunicationType.result, componentId);
      await tester.pumpAndSettle();
      expect(find.text('loading'), findsNothing);
      expect(find.byType(pay_sdk.RawGooglePayButton), findsOneWidget);
      expect(_buttonLocked(tester), isFalse);
      expect(results, hasLength(1));
      expect(
        results.single,
        session
            ? isA<PaymentSessionFinished>()
            : isA<PaymentAdvancedFinished>(),
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('$flow preserves button lock until a matching result', (
      tester,
    ) async {
      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      tester
          .widget<pay_sdk.RawGooglePayButton>(
            find.byType(pay_sdk.RawGooglePayButton),
          )
          .onPressed
          ?.call();
      await tester.pumpAndSettle();
      expect(_buttonLocked(tester), isTrue);

      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      expect(_buttonLocked(tester), isTrue);
      _sendEvent(ComponentCommunicationType.result, 'OTHER_COMPONENT');
      await tester.pumpAndSettle();
      expect(_buttonLocked(tester), isTrue);

      _sendEvent(ComponentCommunicationType.result, componentId);
      await tester.pumpAndSettle();
      expect(_buttonLocked(tester), isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }
}

List<ValueNotifier<bool>> _notifiers(WidgetTester tester) => tester
    .widgetList<ValueListenableBuilder<bool>>(
      find.descendant(
        of: find.byType(AdyenGooglePayComponent),
        matching: find.byWidgetPredicate(
          (widget) => widget is ValueListenableBuilder<bool>,
        ),
      ),
    )
    .map((widget) => widget.valueListenable as ValueNotifier<bool>)
    .toList();

bool _buttonLocked(WidgetTester tester) => tester
    .widget<IgnorePointer>(find
        .ancestor(
          of: find.byType(pay_sdk.RawGooglePayButton),
          matching: find.byType(IgnorePointer),
        )
        .first)
    .ignoring;

void _sendEvent(ComponentCommunicationType type, String componentId) =>
    ComponentFlutterApi.instance.onComponentCommunication(
      ComponentCommunicationModel(
        type: type,
        componentId: componentId,
        paymentResult: type == ComponentCommunicationType.result
            ? PaymentResultDTO(
                type: PaymentResultEnum.finished,
                result: PaymentResultModelDTO(resultCode: 'authorised'),
              )
            : null,
      ),
    );

Widget _app(bool session, {Function(PaymentResult)? onPaymentResult}) =>
    MaterialApp(
      home: Scaffold(
        body: AdyenGooglePayComponent(
          configuration: GooglePayComponentConfiguration(
            environment: Environment.test,
            clientKey: 'test_client_key',
            countryCode: 'NL',
            amount: Amount(value: 1000, currency: 'EUR'),
            googlePayConfiguration: const GooglePayConfiguration(
              googlePayEnvironment: GooglePayEnvironment.test,
            ),
          ),
          paymentMethod: const <String, dynamic>{'type': 'googlepay'},
          checkout: session
              ? SessionCheckout(
                  id: 'session_id',
                  sessionData: 'session_data',
                  paymentMethods: const <String, dynamic>{},
                )
              : AdvancedCheckout(
                  onSubmit: (data, [extra]) async =>
                      Finished(resultCode: 'Authorised'),
                  onAdditionalDetails: (_) async =>
                      Finished(resultCode: 'Authorised'),
                ),
          onPaymentResult: onPaymentResult ?? (_) {},
          loadingIndicator: const Text('loading'),
        ),
      ),
    );
