// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_google_pay_component_repository.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MultiComponentAdvancedScreen extends StatelessWidget {
  const MultiComponentAdvancedScreen({
    required this.cardRepository,
    required this.applePayRepository,
    required this.googlePayRepository,
    super.key,
  });

  final AdyenCardComponentRepository cardRepository;
  final AdyenApplePayComponentRepository applePayRepository;
  final AdyenGooglePayComponentRepository googlePayRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Adyen multi component')),
        body: SafeArea(
          child: FutureBuilder<String>(
            future: cardRepository.fetchPaymentMethods(),
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.data == null) {
                return const SizedBox.shrink();
              } else {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildCardWidget(
                        snapshot.data!,
                        context,
                      ),
                      _buildAppleOrGooglePayWidget(
                        snapshot.data!,
                        context,
                      )
                    ],
                  ),
                );
              }
            },
          ),
        ));
  }

  Widget _buildCardWidget(
    String paymentMethods,
    BuildContext context,
  ) {
    final paymentMethod = extractSchemePaymentMethod(paymentMethods);
    final cardComponentConfiguration = CardComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      shopperLocale: Config.shopperLocale,
      cardConfiguration: const CardConfiguration(),
    );
    final advancedCheckout = AdvancedCheckout(
      onSubmit: cardRepository.onSubmit,
      onAdditionalDetails: cardRepository.onAdditionalDetails,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: AdyenCardComponent(
        configuration: cardComponentConfiguration,
        paymentMethod: paymentMethod,
        checkout: advancedCheckout,
        onPaymentResult: (paymentResult) async {
          Navigator.pop(context);
          _dialogBuilder(context, paymentResult);
        },
      ),
    );
  }

  Widget _buildAppleOrGooglePayWidget(
      String paymentMethods, BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildAdyenGooglePayAdvancedComponent(paymentMethods, context);
      case TargetPlatform.iOS:
        return _buildAdyenApplePayAdvancedComponent(paymentMethods, context);
      default:
        throw Exception("Unsupported platform");
    }
  }

  Widget _buildAdyenGooglePayAdvancedComponent(
    String paymentMethods,
    BuildContext context,
  ) {
    final AdvancedCheckout advancedCheckout = AdvancedCheckout(
      onSubmit: googlePayRepository.onSubmit,
      onAdditionalDetails: googlePayRepository.onAdditionalDetails,
    );

    final GooglePayComponentConfiguration googlePayComponentConfiguration =
        GooglePayComponentConfiguration(
      environment: Environment.test,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      googlePayConfiguration: const GooglePayConfiguration(
        googlePayEnvironment: Config.googlePayEnvironment,
      ),
    );

    final GooglePayButtonStyle googlePayButtonStyle = GooglePayButtonStyle(
      theme: GooglePayButtonTheme.dark,
      type: GooglePayButtonType.buy,
      width: double.infinity,
      cornerRadius: 4,
    );

    final paymentMethod = _extractGooglePayPaymentMethod(paymentMethods);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: AdyenGooglePayComponent(
        configuration: googlePayComponentConfiguration,
        paymentMethod: paymentMethod,
        checkout: advancedCheckout,
        style: googlePayButtonStyle,
        loadingIndicator: const CircularProgressIndicator(),
        onPaymentResult: (paymentResult) {
          Navigator.pop(context);
          _dialogBuilder(context, paymentResult);
        },
      ),
    );
  }

  Widget _buildAdyenApplePayAdvancedComponent(
    String paymentMethods,
    BuildContext context,
  ) {
    final ApplePayComponentConfiguration applePayComponentConfiguration =
        ApplePayComponentConfiguration(
      environment: Environment.test,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      applePayConfiguration: _createApplePayConfiguration(),
    );

    final AdvancedCheckout advancedCheckout = AdvancedCheckout(
      onSubmit: applePayRepository.onSubmit,
      onAdditionalDetails: applePayRepository.onAdditionalDetailsMock,
    );
    final paymentMethod = _extractPaymentMethod(paymentMethods);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: AdyenApplePayComponent(
        configuration: applePayComponentConfiguration,
        paymentMethod: paymentMethod,
        checkout: advancedCheckout,
        loadingIndicator: const CircularProgressIndicator(),
        style: ApplePayButtonStyle(
          theme: ApplePayButtonTheme.black,
          type: ApplePayButtonType.buy,
          width: double.infinity,
          height: 56,
        ),
        onPaymentResult: (paymentResult) {
          Navigator.pop(context);
          _dialogBuilder(context, paymentResult);
        },
      ),
    );
  }

  ApplePayConfiguration _createApplePayConfiguration() {
    return ApplePayConfiguration(
      merchantId: Config.merchantId,
      merchantName: Config.merchantName,
      allowOnboarding: true,
      applePaySummaryItems: [
        ApplePaySummaryItem(
          label: "Product A",
          amount: Amount(value: 5000, currency: "EUR"),
          type: ApplePaySummaryItemType.definite,
        ),
        ApplePaySummaryItem(
          label: "Product B",
          amount: Amount(value: 2500, currency: "EUR"),
          type: ApplePaySummaryItemType.definite,
        ),
        ApplePaySummaryItem(
          label: "Discount",
          amount: Amount(value: -1000, currency: "EUR"),
          type: ApplePaySummaryItemType.definite,
        ),
        ApplePaySummaryItem(
          label: "Total",
          amount: Config.amount,
          type: ApplePaySummaryItemType.definite,
        ),
      ],
      requiredShippingContactFields: [
        ApplePayContactField.name,
        ApplePayContactField.postalAddress,
      ],
      shippingContact: ApplePayContact(
        givenName: "John",
        familyName: "Doe",
        addressLines: ["Simon Carmiggeltstraat 6"],
        postalCode: "1011 DJ",
        city: "Amsterdam",
        country: "Netherlands",
      ),
      applePayShippingType: ApplePayShippingType.shipping,
      allowShippingContactEditing: true,
      shippingMethods: [
        ApplePayShippingMethod(
          label: "Standard shipping",
          detail: "DHL",
          amount: Amount(value: 1000, currency: "EUR"),
          identifier: "identifier 1",
          startDate: DateTime.now().add(const Duration(days: 2)),
          endDate: DateTime.now().add(const Duration(days: 5)),
        ),
        ApplePayShippingMethod(
          label: "Store pick up",
          detail: "Weekdays, from 9:00 am to 6:00 pm",
          amount: Amount(value: 0, currency: "EUR"),
          identifier: "identifier 2",
        ),
      ],
    );
  }

  Map<String, dynamic> _extractPaymentMethod(String paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    return jsonPaymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == "applepay",
      orElse: () => throw Exception("Apple pay payment method not provided"),
    );
  }

  Map<String, dynamic> _extractGooglePayPaymentMethod(String paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    return jsonPaymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == "googlepay",
      orElse: () => throw Exception("Google pay payment method not provided"),
    );
  }

  Map<String, dynamic> extractSchemePaymentMethod(String paymentMethods) {
    Map<String, dynamic> jsonPaymentMethods = jsonDecode(paymentMethods);
    List paymentMethodList = jsonPaymentMethods["paymentMethods"] as List;
    Map<String, dynamic>? paymentMethod = paymentMethodList
        .firstWhereOrNull((paymentMethod) => paymentMethod["type"] == "scheme");

    List storedPaymentMethodList =
        jsonPaymentMethods.containsKey("storedPaymentMethods")
            ? jsonPaymentMethods["storedPaymentMethods"] as List
            : [];
    Map<String, dynamic>? storedPaymentMethod =
        storedPaymentMethodList.firstOrNull;

    return paymentMethod ?? <String, String>{};
  }

  _dialogBuilder(BuildContext context, PaymentResult paymentResult) {
    String title = "";
    String message = "";
    switch (paymentResult) {
      case PaymentAdvancedFinished():
        title = "Finished";
        message = "Result code: ${paymentResult.resultCode}";
      case PaymentSessionFinished():
        title = "Finished";
        message = "Result code: ${paymentResult.resultCode}";
      case PaymentError():
        title = "Error occurred";
        message = "${paymentResult.reason}";
      case PaymentCancelledByUser():
        title = "Cancelled by user";
        message = "Cancelled by user";
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
