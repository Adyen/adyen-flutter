// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_google_pay_component_repository.dart';
import 'package:adyen_checkout_example/screens/component/card/card_component_screen.dart';
import 'package:adyen_checkout_example/screens/component/google_pay/google_pay_component_screen.dart';
import 'package:adyen_checkout_example/screens/drop_in/drop_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  final service = Service();
  final dropInScreen = DropInScreen(
    repository: AdyenDropInRepository(service: service),
  );
  final cardComponentScreen = CardComponentScreen(
    repository: AdyenCardComponentRepository(service: service),
  );
  final googlePayComponentScreen = GooglePayComponentScreen(
    repository: AdyenGooglePayComponentRepository(service: service),
  );

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
    theme: ThemeData(
        useMaterial3: true,
        bottomSheetTheme: const BottomSheetThemeData(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
        )),
    routes: {
      '/': (context) => const MyApp(),
      '/dropInScreen': (context) => dropInScreen,
      '/cardComponentScreen': (context) => cardComponentScreen,
      '/googleApplePay': (context) => googlePayComponentScreen
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
                onPressed: () => Navigator.pushNamed(context, "/dropInScreen"),
                child: const Text("Drop-in")),
            TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, "/cardComponentScreen"),
                child: const Text("Card component")),
            TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, "/googleApplePay"),
                child: const Text("Google and Apple pay component")),
          ],
        ),
      ),
    );
  }
}
