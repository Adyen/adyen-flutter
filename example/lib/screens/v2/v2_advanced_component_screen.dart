import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/screens/v2/v2_payment_method.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class V2AdvancedComponentScreen extends StatefulWidget {
  const V2AdvancedComponentScreen({
    required this.repository,
    this.paymentMethodType = V2PaymentMethodType.card,
    super.key,
  });

  final AdyenDropInRepository repository;
  final V2PaymentMethodType paymentMethodType;

  @override
  State<V2AdvancedComponentScreen> createState() =>
      _V2AdvancedComponentScreenState();
}

class _V2AdvancedComponentScreenState extends State<V2AdvancedComponentScreen> {
  final AdyenComponentController _controller = AdyenComponentController();
  bool _isUnavailable = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutConfiguration =
        buildV2CheckoutConfiguration(widget.paymentMethodType);

    return Scaffold(
      appBar: AppBar(title: const Text('V2 Advanced Component')),
      body: SafeArea(
        child: FutureBuilder<AdvancedCheckout>(
          future: _setupAdvancedCheckout(checkoutConfiguration),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child:
                    Text('Failed to load payment methods: ${snapshot.error}'),
              );
            }

            final paymentMethods = snapshot.data?.paymentMethods;
            if (paymentMethods == null || paymentMethods.isEmpty) {
              return const Center(child: Text('No payment methods available'));
            }

            final paymentMethod = extractV2PaymentMethod(
                paymentMethods, widget.paymentMethodType);
            if (paymentMethod.isEmpty) {
              return Center(
                  child: Text(
                      '${widget.paymentMethodType.txVariant} payment method not found'));
            }

            if (_isUnavailable) {
              return Center(
                  child: Text(
                      '${widget.paymentMethodType.txVariant} is not available'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdyenComponent(
                    controller: _controller,
                    configuration: checkoutConfiguration,
                    paymentMethod: paymentMethod,
                    checkout: snapshot.data!,
                    onPaymentResult: (paymentResult) async =>
                        _endPayment(context, paymentResult),
                  ),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, child) {
                      if (_controller.isReady &&
                          _controller.requiresUserInteraction == false) {
                        return ElevatedButton(
                          onPressed: _controller.submit,
                          child: Text(
                              'Pay with ${widget.paymentMethodType.txVariant}'),
                        );
                      }
                      return child ?? const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
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

  Future<AdvancedCheckout> _setupAdvancedCheckout(
    CheckoutConfiguration checkoutConfiguration,
  ) async {
    final paymentMethods = await widget.repository.fetchPaymentMethods();
    final advancedCheckout = await AdyenCheckout.advanced.setup(
      paymentMethods: paymentMethods,
      checkoutConfiguration: checkoutConfiguration,
      callbacks: AdyenCheckoutCallbacks(
        onSubmit: widget.repository.onSubmit,
        onAdditionalDetails: widget.repository.onAdditionalDetails,
      ),
    );

    return advancedCheckout;
  }
}
