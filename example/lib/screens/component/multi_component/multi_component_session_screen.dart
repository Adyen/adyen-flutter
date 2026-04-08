// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_blik_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_card_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_google_pay_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MultiComponentSessionScreen extends StatelessWidget {
  MultiComponentSessionScreen({
    required this.cardRepository,
    required this.blikRepository,
    required this.applePayRepository,
    required this.googlePayRepository,
    super.key,
  });

  final AdyenCardComponentRepository cardRepository;
  final AdyenBlikComponentRepository blikRepository;
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
      appBar: AppBar(title: const Text('Multi component session')),
      body: SafeArea(
        child: FutureBuilder<SessionCheckout>(
          future: _getSessionCheckout(),
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
                    _buildAppleOrGooglePayWidget(
                      context,
                      sessionCheckout,
                    ),
                    _buildBlikWidget(
                      context,
                      sessionCheckout,
                    ),
                  ],
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget _buildBlikWidget(
    BuildContext context,
    SessionCheckout sessionCheckout,
  ) {
    final Map<String, dynamic> blikPaymentMethod =
        _extractPaymentMethodByType(sessionCheckout.paymentMethods, 'blik');
    if (blikPaymentMethod.isEmpty) {
      return const SizedBox.shrink();
    }

    final blikConfiguration = BlikComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      shopperLocale: Config.shopperLocale,
    );

    return AdyenBlikComponent(
      configuration: blikConfiguration,
      paymentMethod: blikPaymentMethod,
      checkout: sessionCheckout,
      onPaymentResult: (paymentResult) async {
        Navigator.pop(context);
        DialogBuilder.showPaymentResultDialog(paymentResult, context);
      },
    );
  }

  Widget _buildCardWidget(
    BuildContext context,
    SessionCheckout sessionCheckout,
  ) {
    final Map<String, dynamic> schemePaymentMethod =
        _extractPaymentMethodByType(
      sessionCheckout.paymentMethods,
      'scheme',
    );

    return AdyenCardComponent(
      configuration: cardComponentConfiguration,
      paymentMethod: schemePaymentMethod,
      checkout: sessionCheckout,
      onPaymentResult: (paymentResult) async {
        Navigator.pop(context);
        DialogBuilder.showPaymentResultDialog(paymentResult, context);
      },
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

    final Map<String, dynamic> paymentMethod = _extractPaymentMethodByType(
      sessionCheckout.paymentMethods,
      'googlepay',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
        _extractPaymentMethodByType(
      sessionCheckout.paymentMethods,
      'applepay',
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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

  Future<SessionCheckout> _getSessionCheckout() async =>
      await cardRepository.createSessionCheckout(cardComponentConfiguration);

  Map<String, dynamic> _extractPaymentMethodByType(
    Map<String, dynamic> paymentMethods,
    String type,
  ) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    List paymentMethodList = paymentMethods["paymentMethods"] as List;
    return paymentMethodList.firstWhereOrNull(
            (paymentMethod) => paymentMethod["type"] == type) ??
        <String, String>{};
  }
}
