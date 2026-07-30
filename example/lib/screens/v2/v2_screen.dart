import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/screens/v2/v2_blik_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/v2/v2_card_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/v2/v2_google_pay_navigation_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class V2Screen extends StatelessWidget {
  const V2Screen({
    required this.repository,
    super.key,
  });

  final AdyenDropInRepository repository;

  @override
  Widget build(BuildContext context) {
    final isBlikSupported =
        Config.countryCode == 'PL' && Config.amount.currency == 'PLN';

    return Scaffold(
      appBar: AppBar(title: const Text('V2 Example (v6 integration)')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        V2CardNavigationScreen(repository: repository),
                  ),
                ),
                child: const Text('Card component'),
              ),
              if (isBlikSupported)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          V2BlikNavigationScreen(repository: repository),
                    ),
                  ),
                  child: const Text('Blik component'),
                ),
              _buildGoogleOrApplePayComponent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleOrApplePayComponent(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => V2GooglePayNavigationScreen(
                repository: repository,
              ),
            ),
          ),
          child: const Text('Google Pay component'),
        );
      case TargetPlatform.iOS:
        return TextButton(
          onPressed: () => Navigator.pushNamed(context, "/applePayNavigation"),
          child: const Text('Apple Pay component'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
