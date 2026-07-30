import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/screens/v2/v2_payment_method.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class V2SessionComponentScreen extends StatefulWidget {
  const V2SessionComponentScreen({
    required this.repository,
    this.paymentMethodType = V2PaymentMethodType.card,
    super.key,
  });

  final AdyenDropInRepository repository;
  final V2PaymentMethodType paymentMethodType;

  @override
  State<V2SessionComponentScreen> createState() =>
      _V2SessionComponentScreenState();
}

class _V2SessionComponentScreenState extends State<V2SessionComponentScreen> {
  late final Future<SessionCheckout> _sessionCheckoutFuture;
  late final CheckoutConfiguration _checkoutConfiguration;
  bool _isUnavailable = false;

  @override
  void initState() {
    super.initState();
    _checkoutConfiguration =
        buildV2CheckoutConfiguration(widget.paymentMethodType);
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
                  if (_isUnavailable)
                    Text(
                        '${widget.paymentMethodType.txVariant} is not available')
                  else
                    AdyenComponent(
                      configuration: _checkoutConfiguration,
                      paymentMethod: extractV2PaymentMethod(
                        sessionCheckout.paymentMethods,
                        widget.paymentMethodType,
                      ),
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

  void _endPayment(BuildContext context, PaymentResult paymentResult) {
    if (paymentResult is PaymentError &&
        paymentResult.code == PaymentErrorCode.paymentMethodFailure) {
      setState(() => _isUnavailable = true);
      return;
    }
    Navigator.pop(context);
    DialogBuilder.showPaymentResultDialog(paymentResult, context);
  }
}
