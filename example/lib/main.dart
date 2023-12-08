// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/screens/component/card/card_component_screen.dart';
import 'package:adyen_checkout_example/screens/drop_in/drop_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
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
      home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _adyenCheckout = AdyenCheckout();
  final _service = Service();
  late AdyenDropInRepository _adyenDropInRepository;
  late AdyenCardComponentRepository _adyenCardComponentRepository;

  @override
  void initState() {
    super.initState();
    _initRepositories();
    _adyenCheckout.enableConsoleLogging(enabled: true);
  }

  void _initRepositories() {
    _adyenDropInRepository = AdyenDropInRepository(
      adyenCheckout: _adyenCheckout,
      service: _service,
    );

    _adyenCardComponentRepository = AdyenCardComponentRepository(
      adyenCheckout: _adyenCheckout,
      service: _service,
    );
  }

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
                onPressed: () => Navigator.push(context, _buildDropInRoute()),
                child: const Text("Drop-in")),
            TextButton(
                onPressed: () =>
                    Navigator.push(context, _buildCardComponentRoute()),
                child: const Text("Card component")),
          ],
        ),
      ),
    );
  }

  MaterialPageRoute<dynamic> _buildDropInRoute() {
    return MaterialPageRoute(
      builder: (context) => DropInScreen(
        repository: _adyenDropInRepository,
        adyenCheckout: _adyenCheckout,
      ),
    );
  }

  MaterialPageRoute<dynamic> _buildCardComponentRoute() {
    return MaterialPageRoute(
      builder: (context) => CardComponentScreen(
        adyenCheckout: _adyenCheckout,
        repository: _adyenCardComponentRepository,
      ),
    );
  }
}
