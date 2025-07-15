import 'package:flutter/material.dart';

class ApplePayNavigationScreen extends StatelessWidget {
  const ApplePayNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adyen Apple Pay component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: const Text("Apple Pay component session"),
                onPressed: () =>
                    Navigator.pushNamed(context, "/applePaySessionComponent"),
              ),
              TextButton(
                child: const Text("Apple Pay component advanced"),
                onPressed: () =>
                    Navigator.pushNamed(context, "/applePayAdvancedComponent"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
