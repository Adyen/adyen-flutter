// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MultiComponentAdvancedScreen extends StatelessWidget {
  const MultiComponentAdvancedScreen({
    required this.dropInRepository,
    required this.applePayRepository,
    super.key,
  });

  final AdyenDropInRepository dropInRepository;
  final AdyenApplePayComponentRepository applePayRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adyen multi component')),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: dropInRepository.fetchPaymentMethods(),
          builder: (BuildContext context,
              AsyncSnapshot<Map<String, dynamic>> snapshot) {
            if (snapshot.data == null) {
              return const SizedBox.shrink();
            }

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
                  ),
                  _buildBlikWidget(
                    snapshot.data!,
                    context,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlikWidget(
    Map<String, dynamic> paymentMethods,
    BuildContext context,
  ) {
    final paymentMethod = _extractPaymentMethodByType(
      paymentMethods,
      'blik',
    );
    if (paymentMethod.isEmpty) {
      return const SizedBox.shrink();
    }

    final checkoutConfiguration = CheckoutConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      shopperLocale: Config.shopperLocale,
    );

    return AdyenComponent(
      configuration: checkoutConfiguration,
      paymentMethod: paymentMethod,
      checkout: AdvancedCheckout(
        paymentMethods: paymentMethods,
        onSubmit: dropInRepository.onSubmit,
        onAdditionalDetails: dropInRepository.onAdditionalDetails,
      ),
      onPaymentResult: (paymentResult) async {
        Navigator.pop(context);
        DialogBuilder.showPaymentResultDialog(paymentResult, context);
      },
    );
  }

  Widget _buildCardWidget(
    Map<String, dynamic> paymentMethods,
    BuildContext context,
  ) {
    final paymentMethod = _extractPaymentMethodByType(
      paymentMethods,
      'scheme',
    );
    if (paymentMethod.isEmpty) {
      return const SizedBox.shrink();
    }

    final checkoutConfiguration = CheckoutConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      shopperLocale: Config.shopperLocale,
      cardConfiguration: const CardConfiguration(),
    );
    final advancedCheckout = AdvancedCheckout(
      paymentMethods: paymentMethods,
      onSubmit: dropInRepository.onSubmit,
      onAdditionalDetails: dropInRepository.onAdditionalDetails,
    );

    return AdyenComponent(
      configuration: checkoutConfiguration,
      paymentMethod: paymentMethod,
      checkout: advancedCheckout,
      onPaymentResult: (paymentResult) async {
        Navigator.pop(context);
        DialogBuilder.showPaymentResultDialog(paymentResult, context);
      },
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
    final paymentMethod = _extractPaymentMethodByType(
      paymentMethods,
      'googlepay',
    );
    if (paymentMethod.isEmpty) {
      return const SizedBox.shrink();
    }

    final CheckoutConfiguration googlePayCheckoutConfiguration =
        CheckoutConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      googlePayConfiguration: const GooglePayConfiguration(
        googlePayEnvironment: Config.googlePayEnvironment,
      ),
    );
    final AdvancedCheckout advancedCheckout = AdvancedCheckout(
      paymentMethods: paymentMethods,
      onSubmit: dropInRepository.onSubmit,
      onAdditionalDetails: dropInRepository.onAdditionalDetails,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: AdyenComponent(
        configuration: googlePayCheckoutConfiguration,
        paymentMethod: paymentMethod,
        checkout: advancedCheckout,
        onPaymentResult: (paymentResult) async {
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
    final CheckoutConfiguration applePayCheckoutConfiguration =
        CheckoutConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      applePayConfiguration: _createApplePayConfiguration(),
    );

    final AdvancedCheckout advancedCheckout = AdvancedCheckout(
      paymentMethods: paymentMethods,
      onSubmit: applePayRepository.onSubmit,
      onAdditionalDetails: applePayRepository.onAdditionalDetailsMock,
    );
    final paymentMethod = _extractPaymentMethodByType(
      paymentMethods,
      'applepay',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: AdyenApplePayComponent(
        configuration: applePayCheckoutConfiguration,
        paymentMethod: paymentMethod,
        checkout: advancedCheckout,
        loadingIndicator: const CircularProgressIndicator(),
        style: const ApplePayButtonStyle(
          theme: ApplePayButtonTheme.black,
          type: ApplePayButtonType.buy,
        ),
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

  Map<String, dynamic> _extractPaymentMethodByType(
    Map<String, dynamic> paymentMethods,
    String type,
  ) {
    if (paymentMethods.isEmpty) {
      return <String, String>{};
    }

    List paymentMethodList = paymentMethods["paymentMethods"] as List;
    return paymentMethodList.firstWhereOrNull(
          (paymentMethod) => paymentMethod["type"] == type,
        ) ??
        <String, dynamic>{};
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
