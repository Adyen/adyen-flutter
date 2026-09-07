import 'package:adyen_checkout_example/main_common.dart';
import 'package:adyen_checkout_example/network/service.dart';
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
}

void main() {
  testWidgets('shows the checkout flow choices', (tester) async {
    await tester.pumpWidget(CheckoutExample(service: FakeService()));
    expect(find.text('Sessions checkout'), findsOneWidget);
    expect(find.text('Advanced checkout'), findsOneWidget);
  });
}
