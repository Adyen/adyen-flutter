import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/screens/v2/v2_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/v2/v2_payment_method.dart';
import 'package:adyen_checkout_example/screens/v2/v2_session_component_screen.dart';
import 'package:flutter/material.dart';

class V2BlikNavigationScreen extends StatelessWidget {
  const V2BlikNavigationScreen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('V2 Blik component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => V2SessionComponentScreen(
                      repository: repository,
                      paymentMethodType: V2PaymentMethodType.blik,
                    ),
                  ),
                ),
                child: const Text('Blik component session'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => V2AdvancedComponentScreen(
                      repository: repository,
                      paymentMethodType: V2PaymentMethodType.blik,
                    ),
                  ),
                ),
                child: const Text('Blik component advanced'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
