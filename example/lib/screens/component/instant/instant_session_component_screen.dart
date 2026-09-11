import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/repositories/session_checkout_repository.dart';
import 'package:adyen_checkout_example/screens/component/instant/component_submit_button.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_payment_methods.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class InstantSessionComponentScreen extends StatefulWidget {
  final SessionCheckoutRepository repository;

  const InstantSessionComponentScreen({
    required this.repository,
    super.key,
  });

  @override
  State<InstantSessionComponentScreen> createState() =>
      _InstantSessionComponentScreenState();
}

class _InstantSessionComponentScreenState
    extends State<InstantSessionComponentScreen> {
  SessionCheckout? _checkout;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _setupCheckout();
  }

  @override
  void dispose() {
    _checkout?.dispose();
    super.dispose();
  }

  Future<void> _setupCheckout() async {
    try {
      final checkout = await widget.repository.setupCheckout(
        callbacks: SessionCheckoutCallbacks(
          onComplete: _onComplete,
          onFailure: _onFailure,
          onBeforeSubmit: (data) async => BeforeSubmitProceed(data: data),
        ),
      );
      if (!mounted) {
        checkout.dispose();
        return;
      }
      setState(() {
        _checkout = checkout;
        _loading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to set up Instant component session: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onComplete(SessionCheckoutResult result) {
    if (!mounted) return;
    DialogBuilder.showPaymentResultDialog(
      'Payment Result',
      'Result code: ${result.resultCode}',
      context,
    );
  }

  void _onFailure(CheckoutError error) {
    if (!mounted) return;
    DialogBuilder.showPaymentResultDialog(
      'Payment Failed',
      '${error.code}: ${error.message ?? 'Unknown error'}',
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instant component session')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final checkout = _checkout;
    if (checkout == null) {
      return const ComponentUnavailableMessage(
        paymentMethodName: 'Instant component',
      );
    }

    final paymentMethods =
        resolveInstantPaymentMethods(checkout.paymentMethods);
    if (paymentMethods.isEmpty) {
      return const ComponentUnavailableMessage(
        paymentMethodName: 'Instant component',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final paymentMethod in paymentMethods)
            ControlledCheckoutPaymentComponent(
              key: ValueKey(paymentMethod.data),
              checkout: checkout,
              paymentMethod: paymentMethod,
            ),
        ],
      ),
    );
  }
}
