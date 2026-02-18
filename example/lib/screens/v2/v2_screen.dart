import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/screens/v2/v2_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/v2/v2_session_component_screen.dart';
import 'package:flutter/material.dart';

class V2Screen extends StatelessWidget {
  const V2Screen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('V2 Example (v6 integration)')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => V2SessionComponentScreen(
                      repository: repository,
                    ),
                  ),
                ),
                child: const Text('Session component'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => V2AdvancedComponentScreen(
                      repository: repository,
                    ),
                  ),
                ),
                child: const Text('Advanced component'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
