import 'package:flutter/material.dart';

class BlikNavigationScreen extends StatelessWidget {
  const BlikNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adyen BLIK component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/blikSessionComponentScreen'),
                child: const Text('BLIK component session'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                    context, '/blikAdvancedComponentScreen'),
                child: const Text('BLIK component advanced'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
