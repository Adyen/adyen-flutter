import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/checkout_controller.dart';
import 'package:adyen_checkout/src/checkout_runtime.dart';
import 'package:adyen_checkout/src/components/platform/android_platform_view.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';

String componentIdOf(IosPlatformView view) =>
    (view.creationParams as CheckoutPaymentViewParamsDTO).componentId;

String componentIdOfAndroid(AndroidPlatformView view) =>
    (view.creationParams as CheckoutPaymentViewParamsDTO).componentId;

class FakeCheckoutHostApi extends CheckoutHostApi {
  int disposeCheckoutCount = 0;
  final List<String> disposedCheckoutIds = [];
  String regularPaymentMethodsJson = '[{"type":"scheme","name":"Card"}]';

  CheckoutSetupResultDTO _setupResult() => CheckoutSetupResultDTO(
        checkoutId: 'checkout-1',
        regularPaymentMethodsJson: regularPaymentMethodsJson,
        storedPaymentMethodsJson:
            '[{"type":"scheme","name":"Stored Card","id":"stored-1"}]',
      );

  @override
  Future<CheckoutSetupResultDTO> setupSession(
    SessionResponseDTO sessionResponse,
    CheckoutConfigurationDTO configuration,
    CheckoutCallbacksDTO callbacks,
  ) async {
    lastConfiguration = configuration;
    lastCallbacks = callbacks;
    if (failSetupsWithAlreadyActive) {
      throw PlatformException(code: 'CheckoutAlreadyActive');
    }
    return _setupResult();
  }

  int clearActiveCheckoutCount = 0;
  CheckoutConfigurationDTO? lastConfiguration;
  CheckoutCallbacksDTO? lastCallbacks;
  bool failSetupsWithAlreadyActive = false;

  @override
  Future<void> disposeCheckout(String checkoutId) async {
    disposeCheckoutCount++;
    disposedCheckoutIds.add(checkoutId);
  }

  @override
  Future<void> clearActiveCheckout() async {
    clearActiveCheckoutCount++;
    failSetupsWithAlreadyActive = false;
  }

  @override
  Future<AdvancedCheckoutResultDTO> handleAction(
    String actionId,
    String actionJson,
    CheckoutConfigurationDTO configuration,
  ) async =>
      AdvancedCheckoutResultDTO(resultCode: 'Authorised');

  @override
  Future<void> enableConsoleLogging(bool enabled) async {}

  @override
  Future<EncryptedCardDTO> encryptCard(
    UnencryptedCardDTO card,
    String publicKey,
  ) async =>
      EncryptedCardDTO(encryptedCardNumber: 'encrypted');

  @override
  Future<String> encryptBin(String bin, String publicKey) async =>
      'encrypted-bin';

  @override
  Future<bool> validateCardNumber(
          String cardNumber, bool enableLuhnCheck) async =>
      true;

  @override
  Future<bool> validateCardExpiryDate(
    String expiryMonth,
    String expiryYear,
  ) async =>
      true;

  @override
  Future<bool> validateCardSecurityCode(
    String securityCode,
    String? cardBrand,
  ) async =>
      true;

  @override
  Future<String> getThreeDS2SdkVersion() async => '2.4.4';
}

class FakeComponentHostApi extends ComponentHostApi {
  int disposeCount = 0;
  final List<String> disposedCheckoutIds = [];
  final List<String> disposedComponentIds = [];
  int submitCount = 0;
  String? submittedCheckoutId;
  String? submittedComponentId;

  @override
  Future<void> submit(String checkoutId, String componentId) async {
    submitCount++;
    submittedCheckoutId = checkoutId;
    submittedComponentId = componentId;
  }

  @override
  Future<void> dispose(String checkoutId, String componentId) async {
    disposeCount++;
    disposedCheckoutIds.add(checkoutId);
    disposedComponentIds.add(componentId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeCheckoutHostApi checkoutHostApi;
  late FakeComponentHostApi componentHostApi;
  late StreamController<CheckoutEventDTO> eventsController;
  late CheckoutRuntime runtime;

  setUp(() {
    checkoutHostApi = FakeCheckoutHostApi();
    componentHostApi = FakeComponentHostApi();
    eventsController = StreamController<CheckoutEventDTO>.broadcast();
    runtime = CheckoutRuntime(
      checkoutHostApi: checkoutHostApi,
      componentHostApi: componentHostApi,
      platformEvents: eventsController.stream,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async => null,
    );
  });

  Future<Checkout> setUpSession({
    CheckoutConfiguration configuration = const CheckoutConfiguration(
      environment: Environment.test,
      clientKey: 'test_key',
    ),
    CheckoutCallbacks? callbacks,
  }) =>
      runtime.setupSession(
        sessionResponse: const SessionResponse(
          id: 'session-1',
          sessionData: 'session-data',
        ),
        configuration: configuration,
        callbacks: callbacks ??
            CheckoutCallbacks(
              onComplete: (result) {},
              onFailure: (error) {},
              onBeforeSubmit: (data) async => BeforeSubmitProceed(data: data),
            ),
      );

  CheckoutEventDTO completeEvent(String checkoutId) => CheckoutEventDTO(
        type: CheckoutEventTypeDTO.complete,
        checkoutId: checkoutId,
        resultCode: 'Authorised',
        sessionId: 'session-1',
        sessionResult: 'session-result',
      );

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
    runtime.dispose();
    await eventsController.close();
  });

  test('payment methods preserve regular and stored order', () {
    final methods = PaymentMethods.fromJson({
      'paymentMethods': [
        {'type': 'ideal', 'name': 'iDEAL'},
        {'type': 'scheme', 'name': 'Card'},
      ],
      'storedPaymentMethods': [
        {'type': 'scheme', 'name': 'Stored one', 'id': 'one'},
        {'type': 'scheme', 'name': 'Stored two', 'id': 'two'},
      ],
    });

    expect(methods.regular.map((method) => method.type), ['ideal', 'scheme']);
    expect(methods.stored.map((method) => method.id), ['one', 'two']);
    expect(() => methods.regular.add(PaymentMethod(type: 'blik', name: 'BLIK')),
        throwsUnsupportedError);
    expect(methods.regular.first.data['type'], 'ideal');
  });

  test('session setup returns typed checkout and disposes idempotently',
      () async {
    final checkout = await setUpSession();

    expect(checkout, isA<Checkout>());
    expect(checkout.paymentMethods.single.type, 'scheme');
    expect(checkout.storedPaymentMethods.single.id, 'stored-1');

    checkout.dispose();
    checkout.dispose();
    expect(checkoutHostApi.disposeCheckoutCount, 1);
  });

  test('failed session setup releases the native checkout it created',
      () async {
    checkoutHostApi.regularPaymentMethodsJson = '{}';

    await expectLater(
      runtime.setupSession(
        sessionResponse: const SessionResponse(
          id: 'session-1',
          sessionData: 'session-data',
        ),
        configuration: const CheckoutConfiguration(
          environment: Environment.test,
          clientKey: 'test_key',
        ),
        callbacks: CheckoutCallbacks(
          onComplete: (result) {},
          onFailure: (error) {},
          onBeforeSubmit: (data) async => BeforeSubmitProceed(data: data),
        ),
      ),
      throwsA(isA<CheckoutError>()),
    );

    expect(checkoutHostApi.disposedCheckoutIds, ['checkout-1']);
  });

  test('setup recovers a stale native checkout once', () async {
    checkoutHostApi.failSetupsWithAlreadyActive = true;

    final checkout = await runtime.setupSession(
      sessionResponse: const SessionResponse(
        id: 'session-1',
        sessionData: 'session-data',
      ),
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
      ),
      callbacks: CheckoutCallbacks(
        onComplete: (result) {},
        onFailure: (error) {},
        onBeforeSubmit: (data) async => BeforeSubmitProceed(data: data),
      ),
    );

    expect(checkout, isA<Checkout>());
    expect(checkoutHostApi.clearActiveCheckoutCount, 1);
    expect(checkoutHostApi.failSetupsWithAlreadyActive, false);
  });

  test('setup throws alreadyActive while a checkout is tracked', () async {
    await setUpSession();

    await expectLater(
      setUpSession(),
      throwsA(isA<CheckoutError>().having(
        (error) => error.code,
        'code',
        CheckoutError.alreadyActiveCode,
      )),
    );
    expect(checkoutHostApi.clearActiveCheckoutCount, 0);
  });

  test('terminal callback can set up a new checkout', () async {
    Checkout? nextCheckout;
    CheckoutError? setupError;
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) {
          unawaited(() async {
            try {
              nextCheckout = await setUpSession();
            } on CheckoutError catch (error) {
              setupError = error;
            }
          }());
        },
        onFailure: (error) {},
      ),
    );

    eventsController.add(completeEvent(checkout.id));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(setupError, isNull);
    expect(nextCheckout, isA<Checkout>());
  });

  test('action-only handleAction returns the native result code', () async {
    final result = await runtime.handleAction(
      action: Action(type: 'threeDS2', data: const {'token': 'abc'}),
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
      ),
      onAdditionalDetails: (data) async =>
          const AdditionalDetailsResult.completion(resultCode: 'Authorised'),
    );

    expect(result, isA<AdvancedCheckoutResult>());
    expect(result.resultCode, 'Authorised');
  });

  test('utility methods use named public API and validate expiry format',
      () async {
    expect(
      await runtime.encryptCard(
        card: const UnencryptedCard(cardNumber: '4111111111111111'),
        publicKey: 'key',
      ),
      isA<EncryptedCard>(),
    );
    expect(
      await runtime.validateCardExpiryDate(
        expiryMonth: '01',
        expiryYear: '2030',
      ),
      false,
    );
    expect(
      await runtime.validateCardExpiryDate(
        expiryMonth: '01',
        expiryYear: '30',
      ),
      true,
    );
  });

  test('terminal completion disposes checkout and invokes callback', () async {
    CheckoutResult? completedWith;
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) => completedWith = result,
        onFailure: (error) {},
      ),
    );

    eventsController.add(completeEvent(checkout.id));
    await Future<void>.delayed(Duration.zero);

    expect(completedWith?.resultCode, 'Authorised');
    expect(completedWith?.sessionId, 'session-1');
    expect(completedWith?.sessionResult, 'session-result');
    expect(checkout.isDisposed, true);
    expect(checkoutHostApi.disposeCheckoutCount, 1);
  });

  test('terminal failure disposes checkout and invokes callback', () async {
    CheckoutError? receivedError;
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) {},
        onFailure: (error) => receivedError = error,
      ),
    );

    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.failure,
      checkoutId: checkout.id,
      errorCode: CheckoutError.cancellationCode,
      errorMessage: 'Payment cancelled.',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(receivedError?.code, CheckoutError.cancellationCode);
    expect(receivedError?.message, 'Payment cancelled.');
    expect(checkout.isDisposed, true);
    expect(checkoutHostApi.disposeCheckoutCount, 1);
  });

  test('Apple Pay button style is passed to the native configuration',
      () async {
    checkoutHostApi.regularPaymentMethodsJson =
        '[{"type":"applepay","name":"Apple Pay"}]';
    final checkout = await setUpSession(
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
        applePayConfiguration: ApplePayConfiguration(
          merchantId: 'merchant.test',
          merchantName: 'Test merchant',
          amount: Amount(currency: 'EUR', value: 1000),
          countryCode: 'nl',
          buttonStyle: ApplePayButtonStyle(
            theme: ApplePayButtonTheme.white,
            type: ApplePayButtonType.buy,
            cornerRadius: 8,
          ),
        ),
      ),
    );

    final buttonStyle =
        checkoutHostApi.lastConfiguration?.applePayConfiguration?.buttonStyle;
    expect(buttonStyle?.theme, ApplePayButtonThemeDTO.white);
    expect(buttonStyle?.type, ApplePayButtonTypeDTO.buy);
    expect(buttonStyle?.cornerRadius, 8);

    checkout.dispose();
  });

  test('Apple Pay amount and uppercased country code map to the native DTO',
      () async {
    final checkout = await setUpSession(
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
        applePayConfiguration: ApplePayConfiguration(
          merchantId: 'merchant.test',
          merchantName: 'Test merchant',
          amount: Amount(currency: 'EUR', value: 1000),
          countryCode: 'nl',
        ),
      ),
    );

    final applePay = checkoutHostApi.lastConfiguration?.applePayConfiguration;
    expect(applePay?.amount.currency, 'EUR');
    expect(applePay?.amount.value, 1000);
    expect(applePay?.countryCode, 'NL');

    checkout.dispose();
  });

  test('Google Pay country code is uppercased in the native DTO', () async {
    final checkout = await setUpSession(
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
        googlePayConfiguration: GooglePayConfiguration(
          googlePayEnvironment: GooglePayEnvironment.test,
          countryCode: 'nl',
        ),
      ),
    );

    final googlePay = checkoutHostApi.lastConfiguration?.googlePayConfiguration;
    expect(googlePay?.countryCode, 'NL');
    expect(googlePay?.googlePayEnvironment, GooglePayEnvironmentDTO.test);

    checkout.dispose();
  });

  testWidgets(
      'direct method renders natively without a controller when showSubmitButton is true',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final failures = <CheckoutError>[];
    checkoutHostApi.regularPaymentMethodsJson =
        '[{"type":"ideal","name":"iDEAL"}]';
    final paymentMethod = PaymentMethod(type: 'ideal', name: 'iDEAL');
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) {},
        onFailure: failures.add,
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CheckoutPaymentComponent(
          checkout: checkout,
          paymentMethod: paymentMethod,
        ),
      ),
    );
    final platformView = tester.widget<IosPlatformView>(
      find.byType(IosPlatformView),
    );

    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.componentReady,
      checkoutId: checkout.id,
      componentId: componentIdOf(platformView),
      requiresUserInteraction: false,
    ));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));

    expect(failures, isEmpty);
    expect(find.byType(IosPlatformView), findsOneWidget);
    final componentBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byType(IosPlatformView),
        matching: find.byType(SizedBox),
      ),
    );
    // Provisional button height (64) plus container bottom spacing (8) until
    // the native resize event reports the exact height.
    expect(componentBox.height, 72);

    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.resize,
      checkoutId: checkout.id,
      componentId: componentIdOf(platformView),
      height: 56,
    ));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));
    final resizedBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byType(IosPlatformView),
        matching: find.byType(SizedBox),
      ),
    );
    expect(resizedBox.height, 64);

    await tester.pumpWidget(const SizedBox.shrink());
    checkout.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'direct method requires a controller and collapses when showSubmitButton is false',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final controller = CheckoutController();
    checkoutHostApi.regularPaymentMethodsJson =
        '[{"type":"ideal","name":"iDEAL"}]';
    final paymentMethod = PaymentMethod(type: 'ideal', name: 'iDEAL');
    final checkout = await setUpSession(
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
        showSubmitButton: false,
      ),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CheckoutPaymentComponent(
          checkout: checkout,
          paymentMethod: paymentMethod,
          controller: controller,
        ),
      ),
    );
    final platformView = tester.widget<IosPlatformView>(
      find.byType(IosPlatformView),
    );

    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.componentReady,
      checkoutId: checkout.id,
      componentId: componentIdOf(platformView),
      requiresUserInteraction: false,
    ));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.isReady, true);
    expect(controller.requiresUserInteraction, false);
    expect(find.byType(IosPlatformView), findsOneWidget);
    final componentBox = tester.widget<SizedBox>(
      find.ancestor(
        of: find.byType(IosPlatformView),
        matching: find.byType(SizedBox),
      ),
    );
    expect(componentBox.height, 0);

    await controller.submit();
    expect(componentHostApi.submitCount, 1);
    expect(componentHostApi.submittedCheckoutId, checkout.id);
    expect(
      componentHostApi.submittedComponentId,
      componentIdOf(platformView),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    checkout.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  test('checkout controller exposes readiness and submission lifecycle',
      () async {
    final controller = CheckoutController();
    var submitCount = 0;
    attachCheckoutController(controller, () async => submitCount++);

    expect(controller.isReady, false);
    expect(controller.requiresUserInteraction, isNull);
    expect(controller.submit, throwsStateError);

    markCheckoutControllerReady(controller, false);
    await controller.submit();
    expect(controller.requiresUserInteraction, false);
    expect(submitCount, 1);

    detachCheckoutController(controller);
    expect(controller.submit, throwsStateError);
    controller.dispose();
  });

  group('CheckoutPaymentComponent platform view', () {
    final card = PaymentMethod(type: 'scheme', name: 'Card');
    final ideal = PaymentMethod(type: 'ideal', name: 'iDEAL');

    Future<Checkout> setUpCheckout({
      void Function(CheckoutError error)? onFailure,
    }) {
      checkoutHostApi.regularPaymentMethodsJson =
          '[{"type":"scheme","name":"Card"},{"type":"ideal","name":"iDEAL"}]';
      return setUpSession(
        callbacks: CheckoutCallbacks(
          onComplete: (result) {},
          onFailure: onFailure ?? (error) {},
        ),
      );
    }

    Widget host(Widget child) =>
        Directionality(textDirection: TextDirection.ltr, child: child);

    Future<void> sendEvent(WidgetTester tester, CheckoutEventDTO event) async {
      eventsController.add(event);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 300));
    }

    String currentComponentId(WidgetTester tester) => componentIdOf(
          tester.widget<IosPlatformView>(find.byType(IosPlatformView)),
        );

    double? componentHeight(WidgetTester tester) => tester
        .widget<SizedBox>(
          find.ancestor(
            of: find.byType(IosPlatformView),
            matching: find.byType(SizedBox),
          ),
        )
        .height;

    CheckoutEventDTO readyEvent(String checkoutId, String componentId) =>
        CheckoutEventDTO(
          type: CheckoutEventTypeDTO.componentReady,
          checkoutId: checkoutId,
          componentId: componentId,
          requiresUserInteraction: true,
        );

    CheckoutEventDTO resizeEvent(
      String checkoutId,
      String componentId,
      int height,
    ) =>
        CheckoutEventDTO(
          type: CheckoutEventTypeDTO.resize,
          checkoutId: checkoutId,
          componentId: componentId,
          height: height,
        );

    testWidgets('resize updates the component height', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final checkout = await setUpCheckout();
      await tester.pumpWidget(
        host(CheckoutPaymentComponent(checkout: checkout, paymentMethod: card)),
      );
      final componentId = currentComponentId(tester);

      await sendEvent(tester, readyEvent(checkout.id, componentId));
      await sendEvent(tester, resizeEvent(checkout.id, componentId, 300));

      expect(componentHeight(tester), 308);

      await tester.pumpWidget(const SizedBox.shrink());
      checkout.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('duplicate resize keeps the reported height', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final checkout = await setUpCheckout();
      await tester.pumpWidget(
        host(CheckoutPaymentComponent(checkout: checkout, paymentMethod: card)),
      );
      final componentId = currentComponentId(tester);

      await sendEvent(tester, readyEvent(checkout.id, componentId));
      await sendEvent(tester, resizeEvent(checkout.id, componentId, 300));
      await sendEvent(tester, resizeEvent(checkout.id, componentId, 300));

      expect(tester.takeException(), isNull);
      expect(componentHeight(tester), 308);

      await tester.pumpWidget(const SizedBox.shrink());
      checkout.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('failure collapses the component and reports the error',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final failures = <CheckoutError>[];
      final checkout = await setUpCheckout(onFailure: failures.add);
      await tester.pumpWidget(
        host(CheckoutPaymentComponent(checkout: checkout, paymentMethod: card)),
      );
      final componentId = currentComponentId(tester);

      await sendEvent(
        tester,
        CheckoutEventDTO(
          type: CheckoutEventTypeDTO.failure,
          checkoutId: checkout.id,
          componentId: componentId,
          errorCode: CheckoutError.genericCode,
          errorMessage: 'Component failed.',
        ),
      );

      expect(find.byType(IosPlatformView), findsNothing);
      expect(failures.single.code, CheckoutError.genericCode);
      expect(failures.single.message, 'Component failed.');
      expect(checkout.isDisposed, true);

      await tester.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('events for another component are ignored', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final checkout = await setUpCheckout();
      await tester.pumpWidget(
        host(CheckoutPaymentComponent(checkout: checkout, paymentMethod: card)),
      );
      final componentId = currentComponentId(tester);

      await sendEvent(tester, readyEvent(checkout.id, componentId));
      await sendEvent(tester, resizeEvent(checkout.id, componentId, 300));
      await sendEvent(tester, resizeEvent(checkout.id, 'other-component', 500));

      expect(componentHeight(tester), 308);

      await tester.pumpWidget(const SizedBox.shrink());
      checkout.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('removing the widget disposes the native component',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final checkout = await setUpCheckout();
      await tester.pumpWidget(
        host(CheckoutPaymentComponent(checkout: checkout, paymentMethod: card)),
      );
      final componentId = currentComponentId(tester);
      expect(componentHostApi.disposeCount, 0);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(componentHostApi.disposeCount, 1);
      expect(componentHostApi.disposedCheckoutIds, [checkout.id]);
      expect(componentHostApi.disposedComponentIds, [componentId]);

      checkout.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('payment method change recreates the native component',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final checkout = await setUpCheckout();
      await tester.pumpWidget(
        host(CheckoutPaymentComponent(checkout: checkout, paymentMethod: card)),
      );
      final firstComponentId = currentComponentId(tester);

      await tester.pumpWidget(
        host(
            CheckoutPaymentComponent(checkout: checkout, paymentMethod: ideal)),
      );
      final secondComponentId = currentComponentId(tester);

      expect(secondComponentId, isNot(firstComponentId));
      expect(componentHostApi.disposedComponentIds, [firstComponentId]);

      await tester.pumpWidget(const SizedBox.shrink());
      checkout.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('controller swap reattaches the component', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final oldController = CheckoutController();
      final newController = CheckoutController();
      final checkout = await setUpCheckout();
      await tester.pumpWidget(
        host(CheckoutPaymentComponent(
          checkout: checkout,
          paymentMethod: card,
          controller: oldController,
        )),
      );
      await sendEvent(
          tester, readyEvent(checkout.id, currentComponentId(tester)));
      expect(oldController.isReady, true);

      await tester.pumpWidget(
        host(CheckoutPaymentComponent(
          checkout: checkout,
          paymentMethod: card,
          controller: newController,
        )),
      );

      expect(oldController.submit, throwsStateError);
      expect(newController.isReady, false);

      await sendEvent(
          tester, readyEvent(checkout.id, currentComponentId(tester)));

      expect(newController.isReady, true);
      expect(newController.requiresUserInteraction, true);

      await tester.pumpWidget(const SizedBox.shrink());
      oldController.dispose();
      newController.dispose();
      checkout.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Android builds an AndroidPlatformView with view params',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final checkout = await setUpCheckout();
      await tester.pumpWidget(
        host(CheckoutPaymentComponent(checkout: checkout, paymentMethod: card)),
      );

      expect(find.byType(IosPlatformView), findsNothing);
      final platformView = tester.widget<AndroidPlatformView>(
        find.byType(AndroidPlatformView),
      );
      final params =
          platformView.creationParams as CheckoutPaymentViewParamsDTO;
      expect(params.checkoutId, checkout.id);
      expect(params.componentId, isNotEmpty);
      expect(params.isStoredPaymentMethod, false);
      expect(params.paymentMethodJson, contains('"type":"scheme"'));

      await tester.pumpWidget(const SizedBox.shrink());
      expect(
        componentHostApi.disposedComponentIds,
        [componentIdOfAndroid(platformView)],
      );
      checkout.dispose();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('iOS shows a CupertinoActivityIndicator until resized',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final checkout = await setUpCheckout();
      await tester.pumpWidget(
        host(CheckoutPaymentComponent(checkout: checkout, paymentMethod: card)),
      );
      final componentId = currentComponentId(tester);

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      await sendEvent(tester, readyEvent(checkout.id, componentId));
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      await sendEvent(tester, resizeEvent(checkout.id, componentId, 300));
      expect(find.byType(CupertinoActivityIndicator), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      checkout.dispose();
      debugDefaultTargetPlatformOverride = null;
    });
  });

  Future<Object?> callCheckoutCallbacksApi(
    String method,
    List<Object?> arguments,
  ) async {
    const codec = CheckoutCallbacksFlutterApi.pigeonChannelCodec;
    final reply = Completer<ByteData?>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      'dev.flutter.pigeon.adyen_checkout.CheckoutCallbacksFlutterApi.$method',
      codec.encodeMessage(arguments),
      reply.complete,
    );
    final decoded = codec.decodeMessage(await reply.future) as List<Object?>;
    return decoded.first;
  }

  test('payment method callbacks are declared to the native side', () async {
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) {},
        onFailure: (error) {},
        applePay: ApplePayCallbacks(
          onAuthorize: (payment) async =>
              const ApplePayAuthorizationResult.success(),
        ),
        card: CardCallbacks(onBinLookup: (data) {}),
      ),
    );

    final applePay = checkoutHostApi.lastCallbacks?.applePay;
    expect(applePay?.hasOnAuthorize, true);
    expect(applePay?.hasOnSelectShippingMethod, false);
    expect(applePay?.hasOnSelectShippingContact, false);
    expect(applePay?.hasOnChangeCouponCode, false);
    final card = checkoutHostApi.lastCallbacks?.card;
    expect(card?.hasOnBinLookup, true);
    expect(card?.hasOnBinChange, false);

    checkout.dispose();
  });

  test('payment method callbacks are omitted when not provided', () async {
    final checkout = await setUpSession();

    expect(checkoutHostApi.lastCallbacks?.applePay, isNull);
    expect(checkoutHostApi.lastCallbacks?.card, isNull);

    checkout.dispose();
  });

  test('Apple Pay authorize is routed to the Apple Pay callbacks', () async {
    ApplePayAuthorizedPayment? received;
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) {},
        onFailure: (error) {},
        applePay: ApplePayCallbacks(
          onAuthorize: (payment) async {
            received = payment;
            return const ApplePayAuthorizationResult.success();
          },
        ),
      ),
    );

    final result = await callCheckoutCallbacksApi('onApplePayAuthorize', [
      checkout.id,
      ApplePayAuthorizedPaymentDTO(token: 'token', network: 'visa'),
    ]) as ApplePayAuthorizationResultDTO;

    expect(received?.token, 'token');
    expect(result.isSuccess, true);

    checkout.dispose();
  });

  test('Apple Pay authorize fails when the merchant callback throws', () async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (_) {};
    addTearDown(() => FlutterError.onError = originalOnError);
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) {},
        onFailure: (error) {},
        applePay: ApplePayCallbacks(
          onAuthorize: (payment) async => throw StateError('boom'),
        ),
      ),
    );

    final result = await callCheckoutCallbacksApi('onApplePayAuthorize', [
      checkout.id,
      ApplePayAuthorizedPaymentDTO(token: 'token', network: 'visa'),
    ]) as ApplePayAuthorizationResultDTO;

    expect(result.isSuccess, false);

    checkout.dispose();
  });

  test('card BIN events are routed to the card callbacks', () async {
    String? bin;
    BinLookupData? lookup;
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) {},
        onFailure: (error) {},
        card: CardCallbacks(
          onBinChange: (value) => bin = value,
          onBinLookup: (data) => lookup = data,
        ),
      ),
    );

    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.binValue,
      checkoutId: checkout.id,
      binValue: '411111',
    ));
    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.binLookup,
      checkoutId: checkout.id,
      binLookupData: [
        BinLookupDataDTO(
          issuingCountryCode: 'NL',
          brands: [
            BinLookupBrandDTO(
              brand: 'visa',
              supported: true,
              paymentMethodVariant: 'visacredit',
            ),
          ],
        ),
      ],
    ));
    await Future<void>.delayed(Duration.zero);

    expect(bin, '411111');
    expect(lookup?.issuingCountryCode, 'NL');
    expect(lookup?.brands.single.brand, 'visa');

    checkout.dispose();
  });

  test('a throwing card callback does not terminate the checkout', () async {
    final errors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = originalOnError);
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) {},
        onFailure: (error) {},
        card: CardCallbacks(onBinChange: (value) => throw StateError('boom')),
      ),
    );

    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.binValue,
      checkoutId: checkout.id,
      binValue: '411111',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(errors, hasLength(1));
    expect(checkout.isDisposed, false);

    checkout.dispose();
  });

  test('card BIN events after the checkout is disposed are ignored', () async {
    var calls = 0;
    final checkout = await setUpSession(
      callbacks: CheckoutCallbacks(
        onComplete: (result) {},
        onFailure: (error) {},
        card: CardCallbacks(onBinChange: (value) => calls++),
      ),
    );
    final checkoutId = checkout.id;
    checkout.dispose();

    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.binValue,
      checkoutId: checkoutId,
      binValue: '411111',
    ));
    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.binValue,
      checkoutId: 'unknown-checkout',
      binValue: '411111',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(calls, 0);
  });
}
