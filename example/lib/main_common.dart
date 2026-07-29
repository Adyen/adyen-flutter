// ignore_for_file: unused_local_variable

import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_cse_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_instant_component_repository.dart';
import 'package:adyen_checkout_example/repositories/config_repository.dart';
import 'package:adyen_checkout_example/screens/api_only/card_state_notifier.dart';
import 'package:adyen_checkout_example/screens/api_only/custom_card_screen.dart';
import 'package:adyen_checkout_example/screens/component/apple_pay/apple_pay_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/apple_pay/apple_pay_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/apple_pay/apple_pay_session_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_session_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_advanced_screen.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_session_screen.dart';
import 'package:adyen_checkout_example/screens/drop_in/drop_in_screen.dart';
import 'package:adyen_checkout_example/screens/v2/v2_screen.dart';
import 'package:adyen_checkout_example/utils/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void mainCommon(Service service) {
  final adyenApplePayComponentRepository =
      AdyenApplePayComponentRepository(service: service);
  final adyenDropInRepository = AdyenDropInRepository(service: service);
  final adyenInstantComponentRepository =
      AdyenInstantComponentRepository(service: service);
  final adyenCseRepository = AdyenCseRepository(service: service);
  final configRepository = ConfigRepository();

  runApp(MaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'), // English
      Locale('ar'), // Arabic
    ],
    themeMode: ThemeMode.system,
    theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00112C),
      brightness: Brightness.light,
    )),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFEFEFEF),
        brightness: Brightness.dark,
      ),
    ),
    routes: {
      '/': (context) => const MyApp(),
      '/dropInScreen': (context) => DropInScreen(
            repository: adyenDropInRepository,
            configRepository: configRepository,
          ),
      '/applePayNavigation': (context) => const ApplePayNavigationScreen(),
      '/applePaySessionComponent': (context) => ApplePaySessionComponentScreen(
            repository: adyenApplePayComponentRepository,
          ),
      '/applePayAdvancedComponent': (context) =>
          ApplePayAdvancedComponentScreen(
            repository: adyenApplePayComponentRepository,
          ),
      '/instantComponentNavigation': (context) =>
          const InstantNavigationScreen(),
      '/instantSessionComponent': (context) => InstantSessionComponentScreen(
          repository: adyenInstantComponentRepository),
      '/instantAdvancedComponent': (context) => InstantAdvancedComponentScreen(
          repository: adyenInstantComponentRepository),
      '/multiComponentNavigationScreen': (context) =>
          const MultiComponentNavigationScreen(),
      '/multiComponentSessionScreen': (context) => MultiComponentSessionScreen(
            dropInRepository: adyenDropInRepository,
            applePayRepository: adyenApplePayComponentRepository,
          ),
      '/multiComponentAdvancedScreen': (context) =>
          MultiComponentAdvancedScreen(
            dropInRepository: adyenDropInRepository,
            applePayRepository: adyenApplePayComponentRepository,
          ),
      '/customCard': (context) => Provider(
            notifier: CardStateNotifier(adyenCseRepository),
            child: const CustomCardScreen(),
          ),
      '/v2Screen': (context) => V2Screen(
            repository: adyenDropInRepository,
          ),
    },
    initialRoute: "/",
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Checkout example app')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                key: const Key('Drop-in'),
                onPressed: () => Navigator.pushNamed(context, "/dropInScreen"),
                child: const Text("Drop-in")),
            _buildApplePayComponent(context),
            TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, "/instantComponentNavigation"),
                child: const Text("Instant component")),
            TextButton(
                onPressed: () => Navigator.pushNamed(
                    context, "/multiComponentNavigationScreen"),
                child: const Text("Multi component")),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, "/customCard"),
                child: const Text("Custom card (CSE)")),
            TextButton(
                onPressed: () => Navigator.pushNamed(context, "/v2Screen"),
                child: const Text("V2 (v6 integration)")),
          ],
        ),
      ),
    );
  }

  // Google Pay no longer has a dedicated home-screen entry: it's rendered
  // through the generic AdyenComponent (see "V2 (v6 integration)" ->
  // "Google Pay component").
  Widget _buildApplePayComponent(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, "/applePayNavigation"),
            child: const Text("Apple pay component"));
      default:
        return const SizedBox.shrink();
    }
  }
}
