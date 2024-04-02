import 'package:flutter/material.dart';

class MultiComponentNavigationScreen extends StatelessWidget {
  const MultiComponentNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen multi component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // This is not yet supported
              // TextButton(
              //   child: const Text("Multi component session"),
              //   onPressed: () =>
              //       Navigator.pushNamed(context, "/multiComponentSessionScreen"),
              // ),
              TextButton(
                child: const Text("Multi component advanced"),
                onPressed: () => Navigator.pushNamed(
                    context, "/multiComponentAdvancedScreen"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
