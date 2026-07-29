import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/screens/v2/v2_payment_method.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class V2AdvancedComponentScreen extends StatelessWidget {
  const V2AdvancedComponentScreen({
    required this.repository,
    this.paymentMethodType = V2PaymentMethodType.card,
    super.key,
  });

  final AdyenDropInRepository repository;
  final V2PaymentMethodType paymentMethodType;

  @override
  Widget build(BuildContext context) {
    final checkoutConfiguration =
        buildV2CheckoutConfiguration(paymentMethodType);

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

            final paymentMethod =
                extractV2PaymentMethod(paymentMethods, paymentMethodType);
            if (paymentMethod.isEmpty) {
              return Center(
                  child: Text(
                      '${paymentMethodType.txVariant} payment method not found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AdyenComponent(
                configuration: checkoutConfiguration,
                paymentMethod: paymentMethod,
                checkout: snapshot.data!,
                onPaymentResult: (paymentResult) async =>
                    _endPayment(context, paymentResult),
              ),
            );
          },
        ),
      ),
    );
  }

  void _endPayment(BuildContext context, PaymentResult paymentResult) {
    Navigator.pop(context);
    DialogBuilder.showPaymentResultDialog(paymentResult, context);
  }

  Future<AdvancedCheckout> _setupAdvancedCheckout(
    CheckoutConfiguration checkoutConfiguration,
  ) async {
    final paymentMethods = await repository.fetchPaymentMethods();
    final advancedCheckout = await AdyenCheckout.advanced.setup(
      paymentMethods: paymentMethods,
      checkoutConfiguration: checkoutConfiguration,
      callbacks: AdyenCheckoutCallbacks(
        onSubmit: repository.onSubmit,
        onAdditionalDetails: repository.onAdditionalDetails,
      ),
    );

    return advancedCheckout;
  }
}
