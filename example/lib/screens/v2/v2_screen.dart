import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:collection/collection.dart';
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
  late final Future<SessionCheckout> _sessionCheckoutFuture;
  final CheckoutConfiguration checkoutConfiguration = CheckoutConfiguration(
    environment: Config.environment,
    clientKey: Config.clientKey,
    countryCode: Config.countryCode,
    shopperLocale: Config.shopperLocale,
    amount: Config.amount,
    cardConfiguration: const CardConfiguration(
      holderNameRequired: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _sessionCheckoutFuture = setupSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('V2 Example')),
      body: SafeArea(
        child: FutureBuilder<SessionCheckout>(
          future: _sessionCheckoutFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Failed to setup session: ${snapshot.error}');
            }

            final sessionCheckout = snapshot.data;
            if (sessionCheckout == null) {
              return const Text(
                  'Failed to setup session: missing session id');
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('Loaded session id: ${sessionCheckout.id}'),
                    AdyenComponent(
                        configuration: checkoutConfiguration,
                        paymentMethod:
                            _extractPaymentMethod(sessionCheckout.paymentMethods),
                        checkout: sessionCheckout,
                        onPaymentResult: (PaymentResult paymentResult) async {
                          switch (paymentResult) {
                            case PaymentAdvancedFinished():
                              // TODO: Handle this case.
                              throw UnimplementedError();
                            case PaymentSessionFinished():
                              // TODO: Handle this case.
                              throw UnimplementedError();
                            case PaymentCancelledByUser():
                              // TODO: Handle this case.
                              throw UnimplementedError();
                            case PaymentError():
                              // TODO: Handle this case.
                              throw UnimplementedError();
                          }
                        })
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<SessionCheckout> setupSession() async {
    final sessionResponseBody = await widget.repository.fetchSession();
    final sessionResponse = SessionResponse(
      sessionResponseBody['id'],
      sessionResponseBody['sessionData'],
    );

    final checkout = await AdyenCheckout.session.setup(
      sessionResponse: sessionResponse,
      checkoutConfiguration: checkoutConfiguration,
    );

    return checkout;
  }

  Map<String, dynamic> _extractPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    List paymentMethodList = paymentMethods["paymentMethods"] as List;
    Map<String, dynamic> paymentMethod = paymentMethodList.firstWhereOrNull(
            (paymentMethod) => paymentMethod["type"] == "scheme") ??
        <String, String>{};

    List storedPaymentMethodList =
        paymentMethods.containsKey("storedPaymentMethods")
            ? paymentMethods["storedPaymentMethods"] as List
            : [];
    Map<String, dynamic> storedPaymentMethod =
        storedPaymentMethodList.firstOrNull ?? <String, String>{};

    return paymentMethod;
  }
}
