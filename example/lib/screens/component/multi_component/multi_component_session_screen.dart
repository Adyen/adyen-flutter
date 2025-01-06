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

class MultiComponentSessionScreen extends StatelessWidget {
  MultiComponentSessionScreen({
    required this.cardRepository,
    required this.applePayRepository,
    required this.googlePayRepository,
    super.key,
  });

  final AdyenCardComponentRepository cardRepository;
  final AdyenApplePayComponentRepository applePayRepository;
  final AdyenGooglePayComponentRepository googlePayRepository;
  final cardComponentConfiguration = CardComponentConfiguration(
    environment: Config.environment,
    clientKey: Config.clientKey,
    countryCode: Config.countryCode,
    amount: Config.amount,
    shopperLocale: Config.shopperLocale,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Multi component session')),
      body: SafeArea(
        child: FutureBuilder<SessionCheckout>(
            future: createSession(cardComponentConfiguration),
            builder: (
              BuildContext context,
              AsyncSnapshot<SessionCheckout> snapshot,
            ) {
              if (snapshot.data != null) {
                SessionCheckout sessionCheckout = snapshot.data!;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildCardWidget(
                        context,
                        sessionCheckout,
                      ),
                      _buildAppleOrGooglePayWidget(context, sessionCheckout),
                    ],
                  ),
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
      ),
    );
  }

  Widget _buildCardWidget(
    BuildContext context,
    SessionCheckout sessionCheckout,
  ) {
    final Map<String, dynamic> schemePaymentMethod =
        _extractSchemePaymentMethod(sessionCheckout.paymentMethods);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: AdyenCardComponent(
        configuration: cardComponentConfiguration,
        paymentMethod: schemePaymentMethod,
        checkout: sessionCheckout,
        onPaymentResult: (paymentResult) async {
          Navigator.pop(context);
          DialogBuilder.showPaymentResultDialog(paymentResult, context);
        },
      ),
    );
  }

  Widget _buildAppleOrGooglePayWidget(
    BuildContext context,
    SessionCheckout sessionCheckout,
  ) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _buildAdyenGooglePaySessionComponent(
          context,
          sessionCheckout,
        );
      case TargetPlatform.iOS:
        return _buildAdyenApplePaySessionComponent(
          context,
          sessionCheckout,
        );
      default:
        throw Exception("Unsupported platform");
    }
  }

  Widget _buildAdyenGooglePaySessionComponent(
    BuildContext context,
    SessionCheckout sessionCheckout,
  ) {
    final GooglePayComponentConfiguration googlePayComponentConfiguration =
        GooglePayComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      googlePayConfiguration: const GooglePayConfiguration(
        googlePayEnvironment: Config.googlePayEnvironment,
      ),
    );

    final Map<String, dynamic> paymentMethod =
        _extractGooglePayPaymentMethod(sessionCheckout.paymentMethods);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: AdyenGooglePayComponent(
        configuration: googlePayComponentConfiguration,
        paymentMethod: paymentMethod,
        checkout: sessionCheckout,
        loadingIndicator: const CircularProgressIndicator(),
        width: double.infinity,
        style: GooglePayButtonStyle(cornerRadius: 4),
        onPaymentResult: (paymentResult) {
          Navigator.pop(context);
          DialogBuilder.showPaymentResultDialog(paymentResult, context);
        },
      ),
    );
  }

  Widget _buildAdyenApplePaySessionComponent(
    BuildContext context,
    SessionCheckout sessionCheckout,
  ) {
    final ApplePayComponentConfiguration applePayComponentConfiguration =
        ApplePayComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      applePayConfiguration: _createApplePayConfiguration(),
    );

    final Map<String, dynamic> applePayPaymentMethod =
        _extractApplePayPaymentMethod(sessionCheckout.paymentMethods);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: AdyenApplePayComponent(
        configuration: applePayComponentConfiguration,
        paymentMethod: applePayPaymentMethod,
        checkout: sessionCheckout,
        loadingIndicator: const CircularProgressIndicator(),
        width: double.infinity,
        height: 48,
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
          label: "Total",
          amount: Config.amount,
          type: ApplePaySummaryItemType.definite,
        ),
      ],
      applePayShippingType: ApplePayShippingType.shipping,
      allowShippingContactEditing: true,
    );
  }

  Future<SessionCheckout> createSession(
      CardComponentConfiguration configuration) async {
    final sessionResponse = await cardRepository.fetchSession();
    final sessionCheckout = await AdyenCheckout.session.create(
      sessionId: sessionResponse.id,
      sessionData: sessionResponse.sessionData,
      configuration: cardComponentConfiguration,
    );

    return sessionCheckout;
  }

  Map<String, dynamic> _extractApplePayPaymentMethod(
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

  Map<String, dynamic> _extractSchemePaymentMethod(
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
