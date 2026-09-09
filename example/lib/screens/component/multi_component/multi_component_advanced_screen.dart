import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/advanced_checkout_repository.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_view.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class MultiComponentAdvancedScreen extends StatefulWidget {
  final AdvancedCheckoutRepository repository;

  const MultiComponentAdvancedScreen({required this.repository, super.key});

  @override
  State<MultiComponentAdvancedScreen> createState() =>
      _MultiComponentAdvancedScreenState();
}

class _MultiComponentAdvancedScreenState
    extends State<MultiComponentAdvancedScreen> {
  AdvancedCheckout? _checkout;
  bool _loading = true;
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final checkout = await widget.repository.setupCheckout(
        callbacks: AdvancedCheckoutCallbacks(
          onSubmit: widget.repository.onSubmit,
          onAdditionalDetails: widget.repository.onAdditionalDetails,
          onComplete: _onComplete,
          onFailure: _onFailure,
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onComplete(AdvancedCheckoutResult result) {
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
      appBar: AppBar(title: const Text('Multi component advanced')),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error case final error?) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _setupCheckout,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final checkout = _checkout;
    if (checkout == null) {
      return const Center(child: Text('Checkout not available'));
    }

    final isBlikSupported =
        Config.countryCode == 'PL' && Config.amount.currency == 'PLN';

    final cardMethod = checkout.paymentMethods.firstWhereOrNull(
      (m) => m.type == 'scheme',
    );
    final storedCards =
        checkout.storedPaymentMethods.where((m) => m.type == 'scheme').toList();
    final blikMethod = checkout.paymentMethods.firstWhereOrNull(
      (m) => m.type == 'blik',
    );
    final googlePayMethod = checkout.paymentMethods.firstWhereOrNull(
      (method) => method.type == 'googlepay',
    );
    final applePayMethod = checkout.paymentMethods.firstWhereOrNull(
      (m) => m.type == 'applepay',
    );

    return MultiComponentView(
      checkout: checkout,
      cardMethod: cardMethod,
      storedCards: storedCards,
      blikMethod: blikMethod,
      googlePayMethod: googlePayMethod,
      applePayMethod: applePayMethod,
      isBlikSupported: isBlikSupported,
    );
  }
}
