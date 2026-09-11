import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public barrel exposes the v2 checkout contract', () {
    const configuration = CheckoutConfiguration(
      environment: Environment.test,
      clientKey: 'client_key',
    );
    final paymentMethods = PaymentMethods.fromJson(const {
      'paymentMethods': [
        {'type': 'scheme', 'name': 'Card'},
      ],
    });

    expect(configuration.clientKey, 'client_key');
    expect(paymentMethods.regular.single.type, 'scheme');
    expect(Checkout.instance.setup, isA<Function>());
    expect(Checkout.instance.setupAdvanced, isA<Function>());
    expect(Checkout.instance.handleAction, isA<Function>());
    expect(CheckoutPaymentComponent.new, isA<Function>());
  });
}
