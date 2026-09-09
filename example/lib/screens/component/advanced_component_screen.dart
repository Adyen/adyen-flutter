import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/repositories/advanced_checkout_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class AdvancedComponentScreen extends StatefulWidget {
  final AdvancedCheckoutRepository repository;
  final String title;
  final String txVariant;

  const AdvancedComponentScreen({
    required this.repository,
    required this.title,
    required this.txVariant,
    super.key,
  });

  @override
  State<AdvancedComponentScreen> createState() =>
      _AdvancedComponentScreenState();
}

class _AdvancedComponentScreenState extends State<AdvancedComponentScreen> {
  AdvancedCheckout? _checkout;
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
    setState(() => _loading = true);

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
    } catch (error, stackTrace) {
      debugPrint('Failed to set up ${widget.title} advanced component: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _loading = false);
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
    debugPrint(
      '${widget.title} advanced component failed: ${error.code}: ${error.message ?? 'Unknown error'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} component advanced')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final checkout = _checkout;
    if (checkout == null) return const SizedBox.shrink();

    final paymentMethods = <PaymentMethod>[
      ...checkout.paymentMethods.where(
        (method) => method.type == widget.txVariant,
      ),
      ...checkout.storedPaymentMethods.where(
        (method) => method.type == widget.txVariant,
      ),
    ];
    if (paymentMethods.isEmpty) {
      debugPrint('${widget.title} payment method not found');
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final paymentMethod in paymentMethods)
            CheckoutPaymentComponent(
              key: ValueKey(paymentMethod.data),
              checkout: checkout,
              paymentMethod: paymentMethod,
            ),
        ],
      ),
    );
  }
}
