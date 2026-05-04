// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class ApplePayAdvancedComponentScreen extends StatelessWidget {
  const ApplePayAdvancedComponentScreen({
    required this.repository,
    super.key,
  });

  final AdyenApplePayComponentRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adyen Apple Pay component')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildAdyenApplePayAdvancedComponent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdyenApplePayAdvancedComponent() {
    final ApplePayComponentConfiguration applePayComponentConfiguration =
        ApplePayComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      amount: Config.amount,
      applePayConfiguration: _createApplePayConfiguration(),
    );

    return FutureBuilder<Map<String, dynamic>>(
      future: repository.fetchPaymentMethods(),
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasData) {
          final AdvancedCheckout advancedCheckout = AdvancedCheckout(
              onSubmit: repository.onSubmit,
              onAdditionalDetails: repository.onAdditionalDetailsMock);
          final paymentMethod = _extractPaymentMethod(snapshot.data!);

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                style: TextStyle(fontSize: 20),
                "Advanced flow",
              ),
              const SizedBox(height: 8),
              AdyenApplePayComponent(
                configuration: applePayComponentConfiguration,
                paymentMethod: paymentMethod,
                checkout: advancedCheckout,
                loadingIndicator: const CircularProgressIndicator(),
                style: const ApplePayButtonStyle(
                  theme: ApplePayButtonTheme.whiteOutline,
                  type: ApplePayButtonType.book,
                ),
                width: 300,
                height: 56,
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ApplePayConfiguration(
      merchantId: Config.merchantId,
      merchantName: Config.merchantName,
      allowOnboarding: true,
      applePaySummaryItems: _buildApplePaySummaryItems(),
      requiredShippingContactFields: [
        ApplePayContactField.name,
        ApplePayContactField.postalAddress,
      ],
      shippingContact: ApplePayContact(
        givenName: "John",
        familyName: "Doe",
        addressLines: ["Plac Europejski 1"],
        postalCode: "00-844",
        city: "Warsaw",
        country: "Poland",
        countryCode: "PL",
      ),
      applePayShippingType: ApplePayShippingType.shipping,
      allowShippingContactEditing: true,
      supportsCouponCode: true,
      couponCode: "SUMMER10",
      shippingMethods: _buildShippingMethods(today),
      recurringPaymentRequest: ApplePayRecurringPaymentRequest(
        paymentDescription: "Monthly subscription",
        regularBilling: ApplePayRecurringPaymentSummaryItem(
          label: "Monthly billing",
          amount: Config.amount,
          type: ApplePaySummaryItemType.definite,
          startDate: today.add(const Duration(days: 30)),
          intervalUnit: ApplePayRecurringPaymentIntervalUnit.month,
          intervalCount: 1,
        ),
        managementUrl: "https://www.example.com/account",
      ),
      onShippingContactSelected: (contact, currentSummaryItems) =>
          _onShippingContactSelected(contact, currentSummaryItems, today),
      onShippingMethodSelected: _onShippingMethodSelected,
      onCouponCodeChanged: _onCouponCodeChanged,
      onAuthorized: _onAuthorized,
    );
  }

  Future<ApplePayShippingContactUpdate> _onShippingContactSelected(
    ApplePayContact contact,
    List<ApplePaySummaryItem> currentSummaryItems,
    DateTime today,
  ) async {
    if (contact.postalCode == "") {
      return ApplePayShippingContactUpdate(
        summaryItems: currentSummaryItems,
        errors: [
          ApplePayPaymentError(
            type: ApplePayPaymentErrorType.shippingAddress,
            field: ApplePayContactField.postalAddress,
            localizedDescription: "Postal code is required.",
          ),
        ],
      );
    }

    return ApplePayShippingContactUpdate(
      summaryItems: _buildApplePaySummaryItems(),
      shippingMethods: _buildShippingMethods(today),
    );
  }

  Future<ApplePayShippingMethodUpdate> _onShippingMethodSelected(
    ApplePayShippingMethod method,
    List<ApplePaySummaryItem> currentSummaryItems,
  ) async {
    return ApplePayShippingMethodUpdate(
      summaryItems: _buildApplePaySummaryItems(
        shippingAmount: method.amount.value,
      ),
    );
  }

  Future<ApplePayCouponCodeUpdate> _onCouponCodeChanged(
    String couponCode,
    List<ApplePaySummaryItem> currentSummaryItems,
  ) async {
    if (couponCode.toUpperCase() != "SUMMER10") {
      return ApplePayCouponCodeUpdate(
        summaryItems: currentSummaryItems,
        errors: [
          ApplePayPaymentError(
            type: ApplePayPaymentErrorType.couponCode,
            localizedDescription: "Use SUMMER10 for the example discount.",
          ),
        ],
      );
    }

    return ApplePayCouponCodeUpdate(
      summaryItems: _buildApplePaySummaryItems(discountAmount: 1000),
    );
  }

  Future<ApplePayAuthorizationResult> _onAuthorized(
    ApplePayAuthorizedPayment payment,
  ) async {
    if (payment.shippingContact?.postalCode == "") {
      return ApplePayAuthorizationResult.failure(
        errors: [
          ApplePayPaymentError(
            type: ApplePayPaymentErrorType.shippingAddress,
            field: ApplePayContactField.postalAddress,
            localizedDescription: "Postal code is required.",
          ),
        ],
      );
    }

    return const ApplePayAuthorizationResult.success();
  }

  List<ApplePaySummaryItem> _buildApplePaySummaryItems({
    int shippingAmount = 1000,
    int discountAmount = 500,
  }) {
    final totalAmount = 8000 + 2295 + shippingAmount - discountAmount;

    return [
      ApplePaySummaryItem(
        label: "Product A",
        amount: Amount(value: 8000, currency: Config.amount.currency),
        type: ApplePaySummaryItemType.definite,
      ),
      ApplePaySummaryItem(
        label: "Product B",
        amount: Amount(value: 2295, currency: Config.amount.currency),
        type: ApplePaySummaryItemType.definite,
      ),
      ApplePaySummaryItem(
        label: "Shipping",
        amount: Amount(value: shippingAmount, currency: Config.amount.currency),
        type: ApplePaySummaryItemType.definite,
      ),
      ApplePaySummaryItem(
        label: "Discount",
        amount:
            Amount(value: -discountAmount, currency: Config.amount.currency),
        type: ApplePaySummaryItemType.definite,
      ),
      ApplePaySummaryItem(
        label: "Total",
        amount: Amount(value: totalAmount, currency: Config.amount.currency),
        type: ApplePaySummaryItemType.definite,
      ),
    ];
  }

  List<ApplePayShippingMethod> _buildShippingMethods(DateTime today) {
    return [
      ApplePayShippingMethod(
        label: "Standard shipping",
        detail: "DHL",
        amount: Amount(value: 1000, currency: Config.amount.currency),
        identifier: "identifier 1",
        startDate: today.add(const Duration(days: 2)),
        endDate: today.add(const Duration(days: 5)),
      ),
      ApplePayShippingMethod(
        label: "Store pick up",
        detail: "Weekdays, from 9:00 am to 6:00 pm",
        amount: Amount(value: 0, currency: Config.amount.currency),
        identifier: "identifier 2",
      ),
    ];
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
}
