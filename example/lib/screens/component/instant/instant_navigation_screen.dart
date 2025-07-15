import 'package:flutter/material.dart';

class InstantNavigationScreen extends StatelessWidget {
  const InstantNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adyen Instant component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: const Text("Instant component session"),
                onPressed: () =>
                    Navigator.pushNamed(context, "/instantSessionComponent"),
              ),
              TextButton(
                child: const Text("Instant component advanced"),
                onPressed: () =>
                    Navigator.pushNamed(context, "/instantAdvancedComponent"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
