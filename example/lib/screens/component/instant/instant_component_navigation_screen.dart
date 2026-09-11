import 'package:adyen_checkout_example/repositories/advanced_checkout_repository.dart';
import 'package:adyen_checkout_example/repositories/session_checkout_repository.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_session_component_screen.dart';
import 'package:flutter/material.dart';

class InstantComponentNavigationScreen extends StatelessWidget {
  final SessionCheckoutRepository sessionRepository;
  final AdvancedCheckoutRepository advancedRepository;

  const InstantComponentNavigationScreen({
    required this.sessionRepository,
    required this.advancedRepository,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instant component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InstantSessionComponentScreen(
                      repository: sessionRepository,
                    ),
                  ),
                ),
                child: const Text('Instant component session'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InstantAdvancedComponentScreen(
                      repository: advancedRepository,
                    ),
                  ),
                ),
                child: const Text('Instant component advanced'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
