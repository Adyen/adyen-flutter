// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_google_pay_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
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
          child: FutureBuilder<Map<String, dynamic>>(
            future: cardRepository.fetchPaymentMethods(),
            builder: (BuildContext context,
                AsyncSnapshot<Map<String, dynamic>> snapshot) {
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
    Map<String, dynamic> paymentMethods,
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
          DialogBuilder.showPaymentResultDialog(paymentResult, context);
        },
      ),
    );
  }

  Widget _buildAppleOrGooglePayWidget(
      Map<String, dynamic> paymentMethods, BuildContext context) {
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
    Map<String, dynamic> paymentMethods,
    BuildContext context,
  ) {
    final AdvancedCheckout advancedCheckout = AdvancedCheckout(
      onSubmit: googlePayRepository.onSubmit,
      onAdditionalDetails: googlePayRepository.onAdditionalDetails,
    );

    final GooglePayComponentConfiguration googlePayComponentConfiguration =
        GooglePayComponentConfiguration(
      environment: Config.environment,
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
        width: double.infinity,
        onPaymentResult: (paymentResult) {
          Navigator.pop(context);
          DialogBuilder.showPaymentResultDialog(paymentResult, context);
        },
      ),
    );
  }

  Widget _buildAdyenApplePayAdvancedComponent(
    Map<String, dynamic> paymentMethods,
    BuildContext context,
  ) {
    final ApplePayComponentConfiguration applePayComponentConfiguration =
        ApplePayComponentConfiguration(
      environment: Config.environment,
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
        ),
        width: double.infinity,
        height: 56,
        onPaymentResult: (paymentResult) {
          Navigator.pop(context);
          DialogBuilder.showPaymentResultDialog(paymentResult, context);
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
    );
  }

  Map<String, dynamic> _extractPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    return paymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == "applepay",
      orElse: () => throw Exception("Apple pay payment method not provided"),
    );
  }

  Map<String, dynamic> _extractGooglePayPaymentMethod(
      Map<String, dynamic> paymentMethods) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    return paymentMethods["paymentMethods"].firstWhere(
      (paymentMethod) => paymentMethod["type"] == "googlepay",
      orElse: () => throw Exception("Google pay payment method not provided"),
    );
  }

  Map<String, dynamic> extractSchemePaymentMethod(
      Map<String, dynamic> paymentMethods) {
    List paymentMethodList = paymentMethods["paymentMethods"] as List;
    Map<String, dynamic>? paymentMethod = paymentMethodList
        .firstWhereOrNull((paymentMethod) => paymentMethod["type"] == "scheme");

    List storedPaymentMethodList =
        paymentMethods.containsKey("storedPaymentMethods")
            ? paymentMethods["storedPaymentMethods"] as List
            : [];
    Map<String, dynamic>? storedPaymentMethod =
        storedPaymentMethodList.firstOrNull;

    return paymentMethod ?? <String, String>{};
  }
}
