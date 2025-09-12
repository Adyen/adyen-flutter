// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_cse_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_google_pay_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_instant_component_repository.dart';
import 'package:adyen_checkout_example/screens/api_only/card_state_notifier.dart';
import 'package:adyen_checkout_example/screens/api_only/custom_card_screen.dart';
import 'package:adyen_checkout_example/screens/component/apple_pay/apple_pay_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/apple_pay/apple_pay_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/apple_pay/apple_pay_session_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/card/card_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/card/card_bottom_sheet_screen.dart';
import 'package:adyen_checkout_example/screens/component/card/card_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/card/card_session_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/google_pay/google_pay_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/google_pay/google_pay_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/google_pay/google_pay_session_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_advanced_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/instant/instant_session_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_advanced_screen.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_navigation_screen.dart';
import 'package:adyen_checkout_example/screens/component/multi_component/multi_component_session_screen.dart';
import 'package:adyen_checkout_example/screens/drop_in/drop_in_screen.dart';
import 'package:adyen_checkout_example/utils/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void mainCommon(Service service) {
  final adyenGooglePayComponentRepository =
      AdyenGooglePayComponentRepository(service: service);
  final adyenApplePayComponentRepository =
      AdyenApplePayComponentRepository(service: service);
  final adyenCardComponentRepository =
      AdyenCardComponentRepository(service: service);
  final adyenInstantComponentRepository =
      AdyenInstantComponentRepository(service: service);
  final adyenCseRepository = AdyenCseRepository(service: service);

  enableFlutterDriverExtension();
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
            repository: AdyenDropInRepository(service: service),
          ),
      '/cardComponentScreen': (context) => const CardNavigationScreen(),
      '/cardSessionComponentScreen': (context) => CardSessionComponentScreen(
            repository: adyenCardComponentRepository,
          ),
      '/cardAdvancedComponentScreen': (context) => CardAdvancedComponentScreen(
            repository: adyenCardComponentRepository,
          ),
      '/cardBottomSheetScreen': (context) => CardBottomSheetScreen(
            repository: adyenCardComponentRepository,
          ),
      '/googlePayNavigation': (context) => const GooglePayNavigationScreen(),
      '/googlePaySessionComponent': (context) =>
          GooglePaySessionsComponentScreen(
            repository: adyenGooglePayComponentRepository,
          ),
      '/googlePayAdvancedComponent': (context) =>
          GooglePayAdvancedComponentScreen(
            repository: adyenGooglePayComponentRepository,
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
            cardRepository: adyenCardComponentRepository,
            googlePayRepository: adyenGooglePayComponentRepository,
            applePayRepository: adyenApplePayComponentRepository,
          ),
      '/multiComponentAdvancedScreen': (context) =>
          MultiComponentAdvancedScreen(
            cardRepository: adyenCardComponentRepository,
            googlePayRepository: adyenGooglePayComponentRepository,
            applePayRepository: adyenApplePayComponentRepository,
          ),
      '/customCard': (context) => Provider(
            notifier: CardStateNotifier(adyenCseRepository),
            child: const CustomCardScreen(),
          ),
    },
    initialRoute: "/",
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AdyenCheckout.instance.enableConsoleLogging(enabled: false);

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
            TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, "/cardComponentScreen"),
                child: const Text("Card component")),
            _buildGoogleOrApplePayComponent(context),
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
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleOrApplePayComponent(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, "/googlePayNavigation"),
            child: const Text("Google pay component"));
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
