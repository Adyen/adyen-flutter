import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/screens/v2/v2_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/v2/v2_payment_method.dart';
import 'package:adyen_checkout_example/screens/v2/v2_session_component_screen.dart';
import 'package:flutter/material.dart';

class V2InstantNavigationScreen extends StatelessWidget {
  const V2InstantNavigationScreen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('V2 Instant components')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _navigateToInstant(
                  context,
                  V2PaymentMethodType.ideal,
                ),
                child: const Text('iDEAL session'),
              ),
              TextButton(
                onPressed: () => _navigateToInstant(
                  context,
                  V2PaymentMethodType.ideal,
                  useSession: false,
                ),
                child: const Text('iDEAL advanced'),
              ),
              TextButton(
                onPressed: () => _navigateToInstant(
                  context,
                  V2PaymentMethodType.payPal,
                ),
                child: const Text('PayPal session'),
              ),
              TextButton(
                onPressed: () => _navigateToInstant(
                  context,
                  V2PaymentMethodType.payPal,
                  useSession: false,
                ),
                child: const Text('PayPal advanced'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToInstant(
    BuildContext context,
    V2PaymentMethodType paymentMethodType, {
    bool useSession = true,
  }) {
    final screen = useSession
        ? V2SessionComponentScreen(
            repository: repository,
            paymentMethodType: paymentMethodType,
          )
        : V2AdvancedComponentScreen(
            repository: repository,
            paymentMethodType: paymentMethodType,
          );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
