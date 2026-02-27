import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class V2AdvancedComponentScreen extends StatelessWidget {
  const V2AdvancedComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  Widget build(BuildContext context) {
    final checkoutConfiguration = CheckoutConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      amount: Config.amount,
      cardConfiguration: const CardConfiguration(
        // holderNameRequired: true,
      ),
    );

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

            final paymentMethod = _extractPaymentMethod(paymentMethods);
            if (paymentMethod.isEmpty) {
              return const Center(child: Text('Card payment method not found'));
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

  Map<String, dynamic> _extractPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    final paymentMethodList = paymentMethods['paymentMethods'] as List? ?? [];
    final paymentMethod = paymentMethodList.firstWhereOrNull(
          (paymentMethod) => paymentMethod['type'] == 'scheme',
        ) as Map<String, dynamic>? ??
        <String, String>{};

    return paymentMethod;
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
