import 'package:flutter/material.dart';

class InstantNavigationScreen extends StatelessWidget {
  const InstantNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen Instant component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: const Text("Instant component session"),
                onPressed: () =>
                    Navigator.pushNamed(context, "/googlePaySessionComponent"),
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
