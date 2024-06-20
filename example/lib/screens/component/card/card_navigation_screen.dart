// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';

class CardNavigationScreen extends StatefulWidget {
  const CardNavigationScreen({
    super.key,
  });

  @override
  State<CardNavigationScreen> createState() => _CardNavigationScreenState();
}

class _CardNavigationScreenState extends State<CardNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen card component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, "/cardSessionComponentScreen"),
                child: const Text("Card component session"),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                    context, "/cardAdvancedComponentScreen"),
                child: const Text("Card component advanced"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
