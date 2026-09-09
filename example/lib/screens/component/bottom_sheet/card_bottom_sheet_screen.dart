import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/repositories/advanced_checkout_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class CardBottomSheetScreen extends StatelessWidget {
  final AdvancedCheckoutRepository repository;

  const CardBottomSheetScreen({required this.repository, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card component bottom sheet')),
      body: SafeArea(
        child: Center(
          child: TextButton(
            child: const Text('Show bottom sheet'),
            onPressed: () {
              showModalBottomSheet(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                isDismissible: false,
                isScrollControlled: true,
                context: context,
                builder: (BuildContext sheetContext) {
                  return CardBottomSheetContent(repository: repository);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class CardBottomSheetContent extends StatefulWidget {
  final AdvancedCheckoutRepository repository;

  const CardBottomSheetContent({required this.repository, super.key});

  @override
  State<CardBottomSheetContent> createState() => _CardBottomSheetContentState();
}

class _CardBottomSheetContentState extends State<CardBottomSheetContent> {
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

  Widget _buildCardComponents(AdvancedCheckout checkout) {
    final paymentMethods = <PaymentMethod>[
      ...checkout.paymentMethods.where((method) => method.type == 'scheme'),
      ...checkout.storedPaymentMethods.where(
        (method) => method.type == 'scheme',
      ),
    ];
    if (paymentMethods.isEmpty) {
      debugPrint('Card payment method not found');
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final paymentMethod in paymentMethods)
          CheckoutPaymentComponent(
            key: ValueKey(paymentMethod.data),
            checkout: checkout,
            paymentMethod: paymentMethod,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  )
                else if (_checkout != null)
                  _buildCardComponents(_checkout!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
