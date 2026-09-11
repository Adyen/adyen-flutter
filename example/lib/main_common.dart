import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/advanced_checkout_repository.dart';
import 'package:adyen_checkout_example/repositories/session_checkout_repository.dart';
import 'package:adyen_checkout_example/screens/api_only/card_state_notifier.dart';
import 'package:adyen_checkout_example/screens/api_only/custom_card_screen.dart';
import 'package:adyen_checkout_example/screens/component/component_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_component_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_advanced_screen.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_session_screen.dart';
import 'package:adyen_checkout_example/utils/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void mainCommon(Service service) {
  runApp(CheckoutExample(service: service));
}

class CheckoutExample extends StatelessWidget {
  final Service service;

  const CheckoutExample({required this.service, super.key});

  @override
  Widget build(BuildContext context) {
    final sessionRepository = SessionCheckoutRepository(service: service);
    final advancedRepository = AdvancedCheckoutRepository(service: service);

    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00112C),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEFEFEF),
          brightness: Brightness.dark,
        ),
      ),
      routes: {
        '/': (context) => const MyApp(),
        '/cardComponentScreen': (context) => ComponentNavigationScreen(
              sessionRepository: sessionRepository,
              advancedRepository: advancedRepository,
              title: 'Card',
              txVariant: 'scheme',
              showCardBottomSheet: true,
            ),
        '/blikComponentNavigation': (context) => ComponentNavigationScreen(
              sessionRepository: sessionRepository,
              advancedRepository: advancedRepository,
              title: 'BLIK',
              txVariant: 'blik',
            ),
        '/googlePayNavigation': (context) => ComponentNavigationScreen(
              sessionRepository: sessionRepository,
              advancedRepository: advancedRepository,
              title: 'Google Pay',
              txVariant: 'googlepay',
            ),
        '/applePayNavigation': (context) => ComponentNavigationScreen(
              sessionRepository: sessionRepository,
              advancedRepository: advancedRepository,
              title: 'Apple Pay',
              txVariant: 'applepay',
            ),
        '/instantComponentNavigation': (context) =>
            InstantComponentNavigationScreen(
              sessionRepository: sessionRepository,
              advancedRepository: advancedRepository,
            ),
        '/multiComponentNavigationScreen': (context) =>
            const MultiComponentNavigationScreen(),
        '/multiComponentSessionScreen': (context) =>
            MultiComponentSessionScreen(repository: sessionRepository),
        '/multiComponentAdvancedScreen': (context) =>
            MultiComponentAdvancedScreen(repository: advancedRepository),
        '/customCard': (context) => Provider(
              notifier: CardStateNotifier(repository: advancedRepository),
              child: const CustomCardScreen(),
            ),
      },
      initialRoute: '/',
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isBlikSupported =
        Config.countryCode == 'PL' && Config.amount.currency == 'PLN';

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Checkout example app')),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                key: const Key('Card component'),
                onPressed: () =>
                    Navigator.pushNamed(context, '/cardComponentScreen'),
                child: const Text('Card component'),
              ),
              if (isBlikSupported)
                TextButton(
                  key: const Key('BLIK component'),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/blikComponentNavigation'),
                  child: const Text('BLIK component'),
                ),
              TextButton(
                key: const Key('Instant component'),
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/instantComponentNavigation',
                ),
                child: const Text('Instant component'),
              ),
              _buildGoogleOrApplePayComponent(context),
              TextButton(
                key: const Key('Multi component'),
                onPressed: () => Navigator.pushNamed(
                    context, '/multiComponentNavigationScreen'),
                child: const Text('Multi component'),
              ),
              TextButton(
                key: const Key('Custom card (CSE)'),
                onPressed: () => Navigator.pushNamed(context, '/customCard'),
                child: const Text('Custom card (CSE)'),
              ),
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
          key: const Key('Google Pay component'),
          onPressed: () => Navigator.pushNamed(context, '/googlePayNavigation'),
          child: const Text('Google pay component'),
        );
      case TargetPlatform.iOS:
        return TextButton(
          key: const Key('Apple Pay component'),
          onPressed: () => Navigator.pushNamed(context, '/applePayNavigation'),
          child: const Text('Apple pay component'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
