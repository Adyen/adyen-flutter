import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/checkout_controller.dart';
import 'package:adyen_checkout/src/checkout_runtime.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCheckoutHostApi extends CheckoutHostApi {
  int disposeCheckoutCount = 0;

  CheckoutSetupResultDTO _setupResult() => CheckoutSetupResultDTO(
        checkoutId: 'checkout-1',
        regularPaymentMethodsJson: '[{"type":"scheme","name":"Card"}]',
        storedPaymentMethodsJson:
            '[{"type":"scheme","name":"Stored Card","id":"stored-1"}]',
      );

  @override
  Future<CheckoutSetupResultDTO> setupSession(
    SessionResponseDTO sessionResponse,
    CheckoutConfigurationDTO configuration,
  ) async =>
      _setupResult();

  @override
  Future<CheckoutSetupResultDTO> setupAdvanced(
    String paymentMethodsJson,
    CheckoutConfigurationDTO configuration,
  ) async =>
      _setupResult();

  @override
  Future<void> disposeCheckout(String checkoutId) async {
    disposeCheckoutCount++;
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
  });

  tearDown(() async {
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

  test('advanced setup returns typed checkout and disposes idempotently',
      () async {
    final checkout = await runtime.setupAdvanced(
      paymentMethods: PaymentMethods.fromJson({
        'paymentMethods': [
          {'type': 'scheme', 'name': 'Card'},
        ],
      }),
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
      ),
      callbacks: AdvancedCheckoutCallbacks(
        onSubmit: (data) async =>
            const SubmitResult.completion(resultCode: 'Authorised'),
        onAdditionalDetails: (data) async =>
            const AdditionalDetailsResult.completion(resultCode: 'Authorised'),
        onFailure: (error) {},
        onComplete: (result) {},
      ),
    );

    expect(checkout, isA<AdvancedCheckout>());
    expect(checkout.paymentMethods.single.type, 'scheme');
    expect(checkout.storedPaymentMethods, isEmpty);

    checkout.dispose();
    checkout.dispose();
    expect(checkoutHostApi.disposeCheckoutCount, 1);
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

  test('terminal completion invokes callback before disposing checkout',
      () async {
    var completed = false;
    final checkout = await runtime.setupAdvanced(
      paymentMethods: PaymentMethods(),
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
      ),
      callbacks: AdvancedCheckoutCallbacks(
        onSubmit: (data) async =>
            const SubmitResult.completion(resultCode: 'Authorised'),
        onAdditionalDetails: (data) async =>
            const AdditionalDetailsResult.completion(resultCode: 'Authorised'),
        onFailure: (error) {},
        onComplete: (result) => completed = true,
      ),
    );

    eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.complete,
      checkoutId: checkout.id,
      resultCode: 'Authorised',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(completed, true);
    expect(checkout.isDisposed, true);
    expect(checkoutHostApi.disposeCheckoutCount, 1);
  });

  test('terminal failure invokes callback before disposing checkout', () async {
    CheckoutError? receivedError;
    final checkout = await runtime.setupAdvanced(
      paymentMethods: PaymentMethods(),
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
      ),
      callbacks: AdvancedCheckoutCallbacks(
        onSubmit: (data) async =>
            const SubmitResult.completion(resultCode: 'Authorised'),
        onAdditionalDetails: (data) async =>
            const AdditionalDetailsResult.completion(resultCode: 'Authorised'),
        onFailure: (error) => receivedError = error,
        onComplete: (result) {},
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

  testWidgets('Apple Pay passes native button configuration to iOS',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final paymentMethod = PaymentMethod(type: 'applepay', name: 'Apple Pay');
    final checkout = await runtime.setupAdvanced(
      paymentMethods: PaymentMethods(regular: [paymentMethod]),
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
        countryCode: 'NL',
        amount: Amount(currency: 'EUR', value: 1000),
        applePayConfiguration: ApplePayConfiguration(
          merchantId: 'merchant.test',
          merchantName: 'Test merchant',
          buttonStyle: ApplePayButtonStyle(
            theme: ApplePayButtonTheme.white,
            type: ApplePayButtonType.buy,
            cornerRadius: 8,
          ),
          buttonWidth: 180,
          buttonHeight: 48,
        ),
      ),
      callbacks: AdvancedCheckoutCallbacks(
        onSubmit: (data) async =>
            const SubmitResult.completion(resultCode: 'Authorised'),
        onAdditionalDetails: (data) async =>
            const AdditionalDetailsResult.completion(resultCode: 'Authorised'),
        onFailure: (error) {},
        onComplete: (result) {},
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
    expect(platformView.creationParams['applePayButtonTheme'], 'white');
    expect(platformView.creationParams['applePayButtonType'], 'buy');
    expect(platformView.creationParams['applePayButtonCornerRadius'], 8);
    expect(platformView.creationParams['applePayButtonWidth'], 180);
    expect(platformView.creationParams['applePayButtonHeight'], 48);

    await tester.pumpWidget(const SizedBox.shrink());
    checkout.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'alpha.1 direct method stays mounted at zero height and submits through controller',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final controller = CheckoutController();
    final paymentMethod = PaymentMethod(type: 'ideal', name: 'iDEAL');
    final checkout = await runtime.setupAdvanced(
      paymentMethods: PaymentMethods(regular: [paymentMethod]),
      configuration: const CheckoutConfiguration(
        environment: Environment.test,
        clientKey: 'test_key',
      ),
      callbacks: AdvancedCheckoutCallbacks(
        onSubmit: (data) async =>
            const SubmitResult.completion(resultCode: 'Authorised'),
        onAdditionalDetails: (data) async =>
            const AdditionalDetailsResult.completion(resultCode: 'Authorised'),
        onFailure: (error) {},
        onComplete: (result) {},
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
      componentId: platformView.creationParams['componentId'] as String,
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
      platformView.creationParams['componentId'],
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
}
