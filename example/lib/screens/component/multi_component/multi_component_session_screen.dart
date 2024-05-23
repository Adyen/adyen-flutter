// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_google_pay_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MultiComponentSessionScreen extends StatelessWidget {
  const MultiComponentSessionScreen({
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
      appBar: AppBar(title: const Text('Multi component session')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              _buildCardWidget(),
              _buildAppleOrGooglePayWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWidget() {
    final cardComponentConfiguration = CardComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      shopperLocale: Config.shopperLocale,
      cardConfiguration: const CardConfiguration(),
    );

    return FutureBuilder<SessionCheckout>(
        future: createSession(cardComponentConfiguration),
        builder: (
          BuildContext context,
          AsyncSnapshot<SessionCheckout> snapshot,
        ) {
          SessionCheckout sessionCheckout = snapshot.data!;
          final paymentMethod =
              _extractSchemePaymentMethod(sessionCheckout.paymentMethodsJson);

          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: AdyenCardComponent(
              configuration: cardComponentConfiguration,
              paymentMethod: paymentMethod,
              checkout: sessionCheckout,
              onPaymentResult: (paymentResult) async {
                Navigator.pop(context);
                DialogBuilder.showPaymentResultDialog(paymentResult, context);
              },
            ),
          );
        });
  }

  Future<SessionCheckout> createSession(
      CardComponentConfiguration cardComponentConfiguration) async {
    final sessionResponse = await cardRepository.fetchSession();
    final sessionCheckout = await AdyenCheckout.session.create(
      sessionId: sessionResponse.id,
      sessionData: sessionResponse.sessionData,
      configuration: cardComponentConfiguration,
    );

    return sessionCheckout;
  }

  Widget _buildAppleOrGooglePayWidget() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildAdyenGooglePaySessionComponent();
      case TargetPlatform.iOS:
        return _buildAdyenApplePaySessionComponent();
      default:
        throw Exception("Unsupported platform");
    }
  }

  Widget _buildAdyenGooglePaySessionComponent() {
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

    return FutureBuilder<SessionCheckout>(
      future: googlePayRepository
          .createSessionCheckout(googlePayComponentConfiguration),
      builder: (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
        if (snapshot.hasData) {
          final SessionCheckout sessionCheckout = snapshot.data!;
          final paymentMethod = _extractGooglePayPaymentMethod(
              sessionCheckout.paymentMethodsJson);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Session flow",
              ),
              const SizedBox(height: 8),
              AdyenGooglePayComponent(
                configuration: googlePayComponentConfiguration,
                paymentMethod: paymentMethod,
                checkout: sessionCheckout,
                loadingIndicator: const CircularProgressIndicator(),
                onPaymentResult: (paymentResult) {
                  Navigator.pop(context);
                  DialogBuilder.showPaymentResultDialog(paymentResult, context);
                },
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildAdyenApplePaySessionComponent() {
    final ApplePayComponentConfiguration applePayComponentConfiguration =
        ApplePayComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      applePayConfiguration: _createApplePayConfiguration(),
    );

    return FutureBuilder<SessionCheckout>(
      future: applePayRepository
          .createSessionCheckout(applePayComponentConfiguration),
      builder: (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
        if (snapshot.hasData) {
          final SessionCheckout sessionCheckout = snapshot.data!;
          final paymentMethod =
              _extractApplePayPaymentMethod(sessionCheckout.paymentMethodsJson);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Session flow",
              ),
              const SizedBox(height: 8),
              AdyenApplePayComponent(
                configuration: applePayComponentConfiguration,
                paymentMethod: paymentMethod,
                checkout: sessionCheckout,
                loadingIndicator: const CircularProgressIndicator(),
                width: 200,
                height: 48,
                onPaymentResult: (paymentResult) {
                  Navigator.pop(context);
                  DialogBuilder.showPaymentResultDialog(paymentResult, context);
                },
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  ApplePayConfiguration _createApplePayConfiguration() {
    return ApplePayConfiguration(
      merchantId: Config.merchantId,
      merchantName: Config.merchantName,
      allowOnboarding: true,
      applePaySummaryItems: [
        ApplePaySummaryItem(
          label: "Total",
          amount: Config.amount,
          type: ApplePaySummaryItemType.definite,
        ),
      ],
      applePayShippingType: ApplePayShippingType.shipping,
      allowShippingContactEditing: true,
    );
  }

  Map<String, dynamic> _extractApplePayPaymentMethod(String paymentMethods) {
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

  Map<String, dynamic> _extractSchemePaymentMethod(String paymentMethods) {
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
}
