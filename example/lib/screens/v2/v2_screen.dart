import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:flutter/material.dart';

class V2Screen extends StatefulWidget {
  const V2Screen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  State<V2Screen> createState() => _V2ScreenState();
}

class _V2ScreenState extends State<V2Screen> {
  late final Future<String> _sessionIdFuture;

  @override
  void initState() {
    super.initState();
    _sessionIdFuture = setupSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('V2 Example')),
      body: SafeArea(
        child: Center(
          child: FutureBuilder<String>(
            future: _sessionIdFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (snapshot.hasError) {
                return Text('Failed to setup session: ${snapshot.error}');
              }

              final sessionId = snapshot.data;
              if (sessionId == null) {
                return const Text(
                    'Failed to setup session: missing session id');
              }

              return Text('Loaded session id: $sessionId');
            },
          ),
        ),
      ),
    );
  }

  Future<String> setupSession() async {
    final sessionResponseBody = await widget.repository.fetchSession();
    final sessionResponse = SessionResponse(
      sessionResponseBody['id'],
      sessionResponseBody['sessionData'],
    );

    final checkoutConfiguration = _createCheckoutConfiguration();
    await AdyenCheckout.session.setup(
      sessionResponse: sessionResponse,
      checkoutConfiguration: checkoutConfiguration,
    );

    return sessionResponse.id;
  }

  CheckoutConfiguration _createCheckoutConfiguration() {
    return CheckoutConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      amount: Config.amount,
      cardConfiguration: const CardConfiguration(
        holderNameRequired: true,
      ),
    );
  }
}
