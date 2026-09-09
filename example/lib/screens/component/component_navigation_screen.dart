import 'package:adyen_checkout_example/repositories/advanced_checkout_repository.dart';
import 'package:adyen_checkout_example/repositories/session_checkout_repository.dart';
import 'package:adyen_checkout_example/screens/component/advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/bottom_sheet/card_bottom_sheet_screen.dart';
import 'package:adyen_checkout_example/screens/component/session_component_screen.dart';
import 'package:flutter/material.dart';

class ComponentNavigationScreen extends StatelessWidget {
  final SessionCheckoutRepository sessionRepository;
  final AdvancedCheckoutRepository advancedRepository;
  final String title;
  final String txVariant;
  final bool showCardBottomSheet;

  const ComponentNavigationScreen({
    required this.sessionRepository,
    required this.advancedRepository,
    required this.title,
    required this.txVariant,
    this.showCardBottomSheet = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$title component')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _openSession(context),
                child: Text('$title component session'),
              ),
              TextButton(
                onPressed: () => _openAdvanced(context),
                child: Text('$title component advanced'),
              ),
              if (showCardBottomSheet)
                TextButton(
                  onPressed: () => _openCardBottomSheet(context),
                  child: const Text('Card component bottom sheet'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSession(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionComponentScreen(
          repository: sessionRepository,
          title: title,
          txVariant: txVariant,
        ),
      ),
    );
  }

  void _openAdvanced(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdvancedComponentScreen(
          repository: advancedRepository,
          title: title,
          txVariant: txVariant,
        ),
      ),
    );
  }

  void _openCardBottomSheet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CardBottomSheetScreen(repository: advancedRepository),
      ),
    );
  }
}
