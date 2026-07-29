import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/screens/v2/v2_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/v2/v2_payment_method.dart';
import 'package:adyen_checkout_example/screens/v2/v2_session_component_screen.dart';
import 'package:flutter/material.dart';

class V2GooglePayNavigationScreen extends StatelessWidget {
  const V2GooglePayNavigationScreen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('V2 Google Pay component')),
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
                      paymentMethodType: V2PaymentMethodType.googlePay,
                    ),
                  ),
                ),
                child: const Text('Google Pay component session'),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => V2AdvancedComponentScreen(
                      repository: repository,
                      paymentMethodType: V2PaymentMethodType.googlePay,
                    ),
                  ),
                ),
                child: const Text('Google Pay component advanced'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
