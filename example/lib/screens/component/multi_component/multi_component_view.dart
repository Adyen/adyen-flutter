import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MultiComponentView extends StatelessWidget {
  final CheckoutFlow checkout;
  final PaymentMethod? cardMethod;
  final List<StoredPaymentMethod> storedCards;
  final PaymentMethod? blikMethod;
  final PaymentMethod? googlePayMethod;
  final PaymentMethod? applePayMethod;
  final bool isBlikSupported;

  const MultiComponentView({
    required this.checkout,
    this.cardMethod,
    this.storedCards = const [],
    this.blikMethod,
    this.googlePayMethod,
    this.applePayMethod,
    this.isBlikSupported = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cardMethod != null)
            CheckoutPaymentComponent(
              checkout: checkout,
              paymentMethod: cardMethod!,
            ),
          for (final stored in storedCards)
            CheckoutPaymentComponent(
              checkout: checkout,
              paymentMethod: stored,
            ),
          if (isBlikSupported && blikMethod != null)
            CheckoutPaymentComponent(
              checkout: checkout,
              paymentMethod: blikMethod!,
            ),
          if (defaultTargetPlatform == TargetPlatform.android &&
              googlePayMethod != null)
            CheckoutPaymentComponent(
              checkout: checkout,
              paymentMethod: googlePayMethod!,
            ),
          if (defaultTargetPlatform == TargetPlatform.iOS &&
              applePayMethod != null)
            CheckoutPaymentComponent(
              checkout: checkout,
              paymentMethod: applePayMethod!,
            ),
        ],
      ),
    );
  }
}
