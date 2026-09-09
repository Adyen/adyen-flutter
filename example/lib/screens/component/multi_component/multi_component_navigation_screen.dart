import 'package:flutter/material.dart';

class MultiComponentNavigationScreen extends StatelessWidget {
  const MultiComponentNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multi component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(
                    context, '/multiComponentSessionScreen'),
                child: const Text('Multi component session'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                    context, '/multiComponentAdvancedScreen'),
                child: const Text('Multi component advanced'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
