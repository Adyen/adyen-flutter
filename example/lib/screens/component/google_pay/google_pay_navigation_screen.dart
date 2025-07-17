import 'package:flutter/material.dart';

class GooglePayNavigationScreen extends StatelessWidget {
  const GooglePayNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adyen Google Pay component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                child: const Text("Google Pay component session"),
                onPressed: () =>
                    Navigator.pushNamed(context, "/googlePaySessionComponent"),
              ),
              TextButton(
                child: const Text("Google Pay component advanced"),
                onPressed: () =>
                    Navigator.pushNamed(context, "/googlePayAdvancedComponent"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
