import 'package:adyen_checkout_example/repositories/session_checkout_repository.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_session_component_screen.dart';
import 'package:flutter/material.dart';

class InstantComponentNavigationScreen extends StatelessWidget {
  final SessionCheckoutRepository sessionRepository;

  const InstantComponentNavigationScreen({
    required this.sessionRepository,
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
            ],
          ),
        ),
      ),
    );
  }
}
