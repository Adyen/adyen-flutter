import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/extensions/card_configuration_extension.dart';
import 'package:adyen_checkout_example/repositories/adyen_drop_in_repository.dart';
import 'package:adyen_checkout_example/repositories/config_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class DropInScreen extends StatelessWidget {
  const DropInScreen({
    required this.repository,
    required this.configRepository,
    super.key,
  });

  final AdyenDropInRepository repository;
  final ConfigRepository configRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adyen Drop-in')),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => startDropInSessions(context),
                key: const Key('Drop-in sessions flow'),
                child: const Text("Drop-in sessions flow"),
              ),
              TextButton(
                onPressed: () => startDropInAdvancedFlow(context),
                key: const Key('Drop-in advanced flow'),
                child: const Text("Drop-in advanced flow"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> startDropInSessions(BuildContext context) async {
    try {
      final Map<String, dynamic> sessionResponse =
          await repository.fetchSession();
      final DropInConfiguration dropInConfiguration =
          await _createDropInConfiguration();

      final SessionCheckout sessionCheckout =
          await AdyenCheckout.session.create(
        sessionId: sessionResponse["id"],
        sessionData: sessionResponse["sessionData"],
        configuration: dropInConfiguration,
      );

      final PaymentResult paymentResult =
          await AdyenCheckout.session.startDropIn(
        dropInConfiguration: dropInConfiguration,
        checkout: sessionCheckout,
      );

      if (context.mounted) {
        DialogBuilder.showPaymentResultDialog(paymentResult, context);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<void> startDropInAdvancedFlow(BuildContext context) async {
    try {
      final paymentMethodsResponse = await repository.fetchPaymentMethods();
      final dropInConfiguration = await _createDropInConfiguration();
      final advancedCheckout = AdvancedCheckout(
        onSubmit: repository.onSubmit,
        onAdditionalDetails: repository.onAdditionalDetails,
        partialPayment: PartialPayment(
          onCheckBalance: repository.onCheckBalance,
          onRequestOrder: repository.onRequestOrder,
          onCancelOrder: repository.onCancelOrder,
        ),
      );

      final paymentResult = await AdyenCheckout.advanced.startDropIn(
        dropInConfiguration: dropInConfiguration,
        paymentMethods: paymentMethodsResponse,
        checkout: advancedCheckout,
      );

      if (context.mounted) {
        DialogBuilder.showPaymentResultDialog(paymentResult, context);
      }
    } catch (error) {
      debugPrint(error.toString());
    }
  }

  Future<DropInConfiguration> _createDropInConfiguration() async {
    CardConfiguration cardsConfiguration = await _createCardConfiguration();

    ApplePayConfiguration applePayConfiguration = ApplePayConfiguration(
      merchantId: Config.merchantId,
      merchantName: Config.merchantName,
    );

    const GooglePayConfiguration googlePayConfiguration =
        GooglePayConfiguration(
      googlePayEnvironment: Config.googlePayEnvironment,
      shippingAddressRequired: true,
      billingAddressRequired: true,
    );

    //To support CashAppPay on iOS please add "pod 'Adyen/CashAppPay'" to your Podfile.
    final String returnUrl = await repository.determineBaseReturnUrl();
    final CashAppPayConfiguration cashAppPayConfiguration =
        CashAppPayConfiguration(
      cashAppPayEnvironment: CashAppPayEnvironment.sandbox,
      returnUrl: returnUrl,
    );

    //To support TWINT on iOS please add "pod 'Adyen/AdyenTwint'" to your Podfile.
    const TwintConfiguration twintConfiguration = TwintConfiguration(
      iosCallbackAppScheme: "com.mydomain.adyencheckout",
    );

    final StoredPaymentMethodConfiguration storedPaymentMethodConfiguration =
        StoredPaymentMethodConfiguration(
      showPreselectedStoredPaymentMethod: false,
      isRemoveStoredPaymentMethodEnabled: true,
      deleteStoredPaymentMethodCallback: repository.deleteStoredPaymentMethod,
    );

    final DropInConfiguration dropInConfiguration = DropInConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      shopperLocale: Config.shopperLocale,
      amount: Config.amount,
      cardConfiguration: cardsConfiguration,
      applePayConfiguration: applePayConfiguration,
      googlePayConfiguration: googlePayConfiguration,
      cashAppPayConfiguration: cashAppPayConfiguration,
      twintConfiguration: twintConfiguration,
      storedPaymentMethodConfiguration: storedPaymentMethodConfiguration,
    );

    return dropInConfiguration;
  }

  Future<CardConfiguration> _createCardConfiguration() async {
    final CardConfiguration cardConfiguration =
        await configRepository.loadCardConfiguration();
    return cardConfiguration.copyWith(
      onBinLookup: _onBinLookup,
      onBinValue: _onBinValue,
    );
  }

  void _onBinLookup(List<BinLookupData> binLookupDataList) {
    // Bin lookup data based on bin value input. Supports co-branded cards.
    // for (final binLookupData in binLookupDataList) {
    //   debugPrint("Bin lookup data: brand:${binLookupData.brand}");
    // }
  }

  void _onBinValue(String binValue) {
    // Bin value entered by the shopper.
    // debugPrint("Bin value: $binValue");
  }
}
