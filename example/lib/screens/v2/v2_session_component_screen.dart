import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class V2SessionComponentScreen extends StatefulWidget {
  const V2SessionComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  State<V2SessionComponentScreen> createState() =>
      _V2SessionComponentScreenState();
}

class _V2SessionComponentScreenState extends State<V2SessionComponentScreen> {
  late final Future<SessionCheckout> _sessionCheckoutFuture;
  final CheckoutConfiguration _checkoutConfiguration = CheckoutConfiguration(
    environment: Config.environment,
    clientKey: Config.clientKey,
    countryCode: Config.countryCode,
    shopperLocale: Config.shopperLocale,
    amount: Config.amount,
    cardConfiguration: const CardConfiguration(),
  );

  @override
  void initState() {
    super.initState();
    _sessionCheckoutFuture = _setupSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('V2 Session Component')),
      body: SafeArea(
        child: FutureBuilder<SessionCheckout>(
          future: _sessionCheckoutFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                  child: Text('Failed to setup session: ${snapshot.error}'));
            }

            final sessionCheckout = snapshot.data;
            if (sessionCheckout == null) {
              return const Center(
                  child: Text('Failed to setup session: missing session id'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Loaded session id: ${sessionCheckout.id}'),
                  const SizedBox(height: 16),
                  AdyenComponent(
                    configuration: _checkoutConfiguration,
                    paymentMethod:
                        _extractPaymentMethod(sessionCheckout.paymentMethods),
                    checkout: sessionCheckout,
                    onPaymentResult: (paymentResult) async =>
                        _endPayment(context, paymentResult),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<SessionCheckout> _setupSession() async {
    final sessionResponseBody = await widget.repository.fetchSession();
    final sessionResponse = SessionResponse(
      sessionResponseBody['id'],
      sessionResponseBody['sessionData'],
    );

    return AdyenCheckout.session.setup(
      sessionResponse: sessionResponse,
      checkoutConfiguration: _checkoutConfiguration,
    );
  }

  Map<String, dynamic> _extractPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    final paymentMethodList = paymentMethods['paymentMethods'] as List? ?? [];
    final paymentMethod = paymentMethodList.firstWhereOrNull(
          (paymentMethod) => paymentMethod['type'] == 'scheme',
        ) as Map<String, dynamic>? ??
        <String, String>{};

    return paymentMethod;
  }

  void _endPayment(BuildContext context, PaymentResult paymentResult) {
    Navigator.pop(context);
    DialogBuilder.showPaymentResultDialog(paymentResult, context);
  }
}
