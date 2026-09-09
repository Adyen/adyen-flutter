import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/repositories/session_checkout_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class SessionComponentScreen extends StatefulWidget {
  final SessionCheckoutRepository repository;
  final String title;
  final String txVariant;

  const SessionComponentScreen({
    required this.repository,
    required this.title,
    required this.txVariant,
    super.key,
  });

  @override
  State<SessionComponentScreen> createState() => _SessionComponentScreenState();
}

class _SessionComponentScreenState extends State<SessionComponentScreen> {
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
    setState(() => _loading = true);

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
      debugPrint('Failed to set up ${widget.title} session component: $error');
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
    debugPrint(
      '${widget.title} session component failed: ${error.code}: ${error.message ?? 'Unknown error'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.title} component session')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final paymentMethod = _checkout?.paymentMethods
        .firstWhereOrNull((method) => method.type == widget.txVariant);
    if (paymentMethod == null) {
      debugPrint('${widget.title} payment method not found');
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CheckoutPaymentComponent(
        key: ValueKey(paymentMethod.data),
        checkout: _checkout!,
        paymentMethod: paymentMethod,
      ),
    );
  }
}
