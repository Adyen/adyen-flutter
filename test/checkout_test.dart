import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/checkout_coordinator.dart';
import 'package:adyen_checkout/src/checkout_gateway.dart';
import 'package:adyen_checkout/src/components/platform/ios_platform_view.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCheckoutGateway implements CheckoutGateway {
  final eventsController = StreamController<CheckoutEventDTO>.broadcast();
  int disposeCheckoutCount = 0;
  int disposeComponentCount = 0;

  @override
  Stream<CheckoutEventDTO> get events => eventsController.stream;

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

  @override
  Future<void> submit(String checkoutId, String componentId) async {}

  @override
  Future<void> disposeComponent(String checkoutId, String componentId) async {
    disposeComponentCount++;
  }

  Future<void> close() => eventsController.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeCheckoutGateway gateway;

  setUp(() {
    gateway = FakeCheckoutGateway();
    CheckoutCoordinator.replaceSharedForTesting(gateway);
  });

  tearDown(() async {
    await gateway.close();
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
    final checkout = await Checkout.setupAdvanced(
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
    expect(gateway.disposeCheckoutCount, 1);
  });

  test('second checkout setup fails while the first is active', () async {
    final callbacks = AdvancedCheckoutCallbacks(
      onSubmit: (data) async =>
          const SubmitResult.completion(resultCode: 'Authorised'),
      onAdditionalDetails: (data) async =>
          const AdditionalDetailsResult.completion(resultCode: 'Authorised'),
      onFailure: (error) {},
      onComplete: (result) {},
    );
    const configuration = CheckoutConfiguration(
      environment: Environment.test,
      clientKey: 'test_key',
    );
    final first = await Checkout.setupAdvanced(
      paymentMethods: PaymentMethods(),
      configuration: configuration,
      callbacks: callbacks,
    );

    await expectLater(
      Checkout.setupAdvanced(
        paymentMethods: PaymentMethods(),
        configuration: configuration,
        callbacks: callbacks,
      ),
      throwsA(isA<CheckoutError>().having(
        (error) => error.code,
        'code',
        CheckoutError.alreadyActiveCode,
      )),
    );
    first.dispose();
  });

  test('utility methods use named public API and validate expiry format',
      () async {
    expect(
      await Checkout.encryptCard(
        card: const UnencryptedCard(cardNumber: '4111111111111111'),
        publicKey: 'key',
      ),
      isA<EncryptedCard>(),
    );
    expect(
      await Checkout.validateCardExpiryDate(
        expiryMonth: '01',
        expiryYear: '2030',
      ),
      false,
    );
    expect(
      await Checkout.validateCardExpiryDate(
        expiryMonth: '01',
        expiryYear: '30',
      ),
      true,
    );
  });

  test('terminal completion invokes callback before disposing checkout',
      () async {
    var completed = false;
    final checkout = await Checkout.setupAdvanced(
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

    gateway.eventsController.add(CheckoutEventDTO(
      type: CheckoutEventTypeDTO.complete,
      checkoutId: checkout.id,
      resultCode: 'Authorised',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(completed, true);
    expect(checkout.isDisposed, true);
    expect(gateway.disposeCheckoutCount, 1);
  });

  testWidgets('Apple Pay passes native button configuration to iOS',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final paymentMethod = PaymentMethod(type: 'applepay', name: 'Apple Pay');
    final checkout = await Checkout.setupAdvanced(
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
