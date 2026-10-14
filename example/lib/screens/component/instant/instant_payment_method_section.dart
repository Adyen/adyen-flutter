import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter/material.dart';

class InstantPaymentMethodSection extends StatelessWidget {
  final CheckoutFlow checkout;
  final PaymentMethod paymentMethod;

  const InstantPaymentMethodSection({
    required this.checkout,
    required this.paymentMethod,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            paymentMethod.name,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        CheckoutPaymentComponent(
          key: ValueKey(paymentMethod.data),
          checkout: checkout,
          paymentMethod: paymentMethod,
        ),
      ],
    );
  }
}
