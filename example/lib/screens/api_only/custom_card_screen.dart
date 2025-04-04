import 'package:adyen_checkout_example/screens/api_only/card_state_notifier.dart';
import 'package:adyen_checkout_example/screens/api_only/card_widget.dart';
import 'package:adyen_checkout_example/utils/provider.dart';
import 'package:flutter/material.dart';

class CustomCardScreen extends StatelessWidget {
  const CustomCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Adyen custom card')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: CardWidget(
                cardModelNotifier: Provider.of<CardStateNotifier>(context)),
          ),
        ),
      ),
    );
  }
}
