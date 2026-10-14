import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/repositories/session_checkout_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class DropInScreen extends StatefulWidget {
  final SessionCheckoutRepository repository;

  const DropInScreen({required this.repository, super.key});

  @override
  State<DropInScreen> createState() => _DropInScreenState();
}

class _DropInScreenState extends State<DropInScreen> {
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
      debugPrint('Failed to set up session checkout: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startDropIn() async {
    try {
      await _checkout?.startDropIn();
    } catch (error, stackTrace) {
      debugPrint('Failed to start Drop-in: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _onComplete(SessionCheckoutResult result) {
    if (!mounted) return;
    DialogBuilder.showPaymentResultDialog(
      'Payment Result',
      'Result code: ${result.resultCode}',
      context,
    );
    // The checkout is terminal after completion; set up a fresh session so
    // Drop-in can be started again.
    _checkout = null;
    _setupCheckout();
  }

  void _onFailure(CheckoutError error) {
    if (!mounted) return;
    DialogBuilder.showPaymentResultDialog(
      'Payment Failed',
      '${error.code}: ${error.message ?? 'Unknown error'}',
      context,
    );
    _checkout = null;
    _setupCheckout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drop-in session')),
      body: SafeArea(
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : TextButton(
                  onPressed: _startDropIn,
                  child: const Text('Start Drop-in'),
                ),
        ),
      ),
    );
  }
}
