import 'dart:async';
import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/navigation/card_component_screen.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const MaterialApp(localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ], supportedLocales: [
    Locale('en'), // English
    Locale('ar'), // Arabic
  ], home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _adyenCheckout = AdyenCheckout();
  final _service = Service();
  late AdyenDropInRepository _adyenDropInRepository;
  late AdyenCardComponentRepository _adyenCardComponentRepository;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _adyenCheckout.enableLogging(loggingEnabled: true);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    _adyenDropInRepository = AdyenDropInRepository(
      adyenCheckout: _adyenCheckout,
      service: _service,
    );

    _adyenCardComponentRepository = AdyenCardComponentRepository(
      adyenCheckout: _adyenCheckout,
      service: _service,
    );

    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _adyenCheckout.getPlatformVersion();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
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
            Text('Running on: $_platformVersion\n'),
            TextButton(
                onPressed: () async {
                  final result = await startDropInSessions();
                  _dialogBuilder(context, result);
                },
                child: const Text("DropIn sessions")),
            TextButton(
                onPressed: () async {
                  final result = await startDropInAdvancedFlow();
                  _dialogBuilder(context, result);
                },
                child: const Text("DropIn advanced flow")),
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CardComponentScreen(
                              repository: _adyenCardComponentRepository,
                            )),
                  );
                },
                child: const Text("Card component scroll view")),
            TextButton(
                onPressed: () async {
                  await _adyenCardComponentRepository
                      .createSession()
                      .then((sessionResponse) async {
                    final cardComponentConfiguration =
                        CardComponentConfiguration(
                      environment: Config.environment,
                      clientKey: Config.clientKey,
                      countryCode: Config.countryCode,
                      amount: Config.amount,
                      shopperLocale: Config.shopperLocale,
                      cardConfiguration: const CardConfiguration(),
                    );

                    final session = await _adyenCheckout.createSession(
                      sessionResponse.id,
                      sessionResponse.sessionData,
                      cardComponentConfiguration,
                    );

                    // ignore: use_build_context_synchronously
                    return showModalBottomSheet(
                        context: context,
                        isDismissible: false,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: SingleChildScrollView(
                                child: Column(
                              children: [
                                Container(height: 8),
                                Container(
                                  width: 48,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey),
                                ),
                                Container(height: 8),
                                Container(
                                  padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom),
                                  child: _buildSessionCardWidget(
                                    context,
                                    session,
                                    cardComponentConfiguration,
                                  ),
                                ),
                              ],
                            )),
                          );
                        });
                  });
                },
                child: const Text("Card component session sheet")),
          ],
        ),
      ),
    );
  }

  Future<PaymentResult> startDropInSessions() async {
    final SessionResponseNetworkModel sessionResponse =
        await _adyenDropInRepository.fetchSession();

    final Session session = Session(
      id: sessionResponse.id,
      sessionData: sessionResponse.sessionData,
      paymentMethodsJson: "",
    );

    const CardConfiguration cardsConfiguration = CardConfiguration(
      showStorePaymentField: true,
    );

    final StoredPaymentMethodConfiguration storedPaymentMethodConfiguration =
        StoredPaymentMethodConfiguration(
      showPreselectedStoredPaymentMethod: true,
      isRemoveStoredPaymentMethodEnabled: true,
      deleteStoredPaymentMethodCallback:
          _adyenDropInRepository.deleteStoredPaymentMethod,
    );

    final CashAppPayConfiguration cashAppPayConfiguration =
        await _createCashAppPayConfiguration();

    const ApplePayConfiguration applePayConfiguration = ApplePayConfiguration(
      merchantId: Config.merchantAccount,
      merchantName: Config.merchantName,
    );

    final DropInConfiguration dropInConfiguration = DropInConfiguration(
      environment: Environment.test,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      shopperLocale: Config.shopperLocale,
      cardConfiguration: cardsConfiguration,
      storedPaymentMethodConfiguration: storedPaymentMethodConfiguration,
      cashAppPayConfiguration: cashAppPayConfiguration,
      applePayConfiguration: applePayConfiguration,
    );

    return await _adyenCheckout.startPayment(
      paymentFlow: DropInSessionFlow(
        dropInConfiguration: dropInConfiguration,
        session: session,
      ),
    );
  }

  Future<PaymentResult> startDropInAdvancedFlow() async {
    final String paymentMethodsResponse =
        await _adyenDropInRepository.fetchPaymentMethods();

    const CardConfiguration cardsConfiguration = CardConfiguration(
      showStorePaymentField: true,
    );

    const ApplePayConfiguration applePayConfiguration = ApplePayConfiguration(
      merchantId: Config.merchantAccount,
      merchantName: Config.merchantName,
    );

    const GooglePayConfiguration googlePayConfiguration =
        GooglePayConfiguration(
      googlePayEnvironment: GooglePayEnvironment.test,
      shippingAddressRequired: true,
      billingAddressRequired: true,
    );

    final CashAppPayConfiguration cashAppPayConfiguration =
        await _createCashAppPayConfiguration();

    final StoredPaymentMethodConfiguration storedPaymentMethodConfiguration =
        StoredPaymentMethodConfiguration(
      showPreselectedStoredPaymentMethod: false,
      isRemoveStoredPaymentMethodEnabled: true,
      deleteStoredPaymentMethodCallback:
          _adyenDropInRepository.deleteStoredPaymentMethod,
    );

    final DropInConfiguration dropInConfiguration = DropInConfiguration(
      environment: Environment.test,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      amount: Config.amount,
      cardConfiguration: cardsConfiguration,
      applePayConfiguration: applePayConfiguration,
      googlePayConfiguration: googlePayConfiguration,
      cashAppPayConfiguration: cashAppPayConfiguration,
      storedPaymentMethodConfiguration: storedPaymentMethodConfiguration,
    );

    return await _adyenCheckout.startPayment(
      paymentFlow: DropInAdvancedFlow(
        dropInConfiguration: dropInConfiguration,
        paymentMethodsResponse: paymentMethodsResponse,
        postPayments: _adyenDropInRepository.postPayments,
        postPaymentsDetails: _adyenDropInRepository.postPaymentsDetails,
      ),
    );
  }

  //To support CashAppPay please add "pod 'Adyen/CashAppPay'" to your Podfile.
  Future<CashAppPayConfiguration> _createCashAppPayConfiguration() async {
    return CashAppPayConfiguration(
      CashAppPayEnvironment.sandbox,
      await _adyenDropInRepository.determineBaseReturnUrl(),
    );
  }

  Widget _buildSessionCardWidget(
    BuildContext context,
    Session session,
    CardComponentConfiguration cardComponentConfiguration,
  ) {
    final paymentMethod = extractPaymentMethod(session.paymentMethodsJson);

    return AdyenCardComponentWidget(
      componentPaymentFlow: CardComponentSessionFlow(
        cardComponentConfiguration: cardComponentConfiguration,
        session: session,
        paymentMethod: paymentMethod,
      ),
      onPaymentResult: (event) async {
        Navigator.pop(context);
        _dialogBuilder(context, event);
      },
    );
  }

  Map<String, dynamic>? extractPaymentMethod(String paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    List paymentMethodList = jsonPaymentMethods["paymentMethods"] as List;
    Map<String, dynamic> paymentMethod = paymentMethodList
        .firstWhere((paymentMethod) => paymentMethod["type"] == "scheme");

    List storedPaymentMethodList =
    jsonPaymentMethods.containsKey("storedPaymentMethods")
        ? jsonPaymentMethods["storedPaymentMethods"] as List
        : [];
    Map<String, dynamic>? storedPaymentMethod =
        storedPaymentMethodList.firstOrNull;

    return storedPaymentMethod;
  }

  _dialogBuilder(BuildContext context, PaymentResult paymentResult) {
    String title = "";
    String message = "";
    switch (paymentResult) {
      case PaymentAdvancedFlowFinished():
        title = "Finished";
        message = "Result code: ${paymentResult.resultCode}";
      case PaymentSessionFinished():
        title = "Finished";
        message = "Result code: ${paymentResult.resultCode}";
      case PaymentCancelledByUser():
        title = "Cancelled by user";
        message = "Drop-in cancelled by user";
      case PaymentError():
        title = "Error occurred";
        message = "${paymentResult.reason}";
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
