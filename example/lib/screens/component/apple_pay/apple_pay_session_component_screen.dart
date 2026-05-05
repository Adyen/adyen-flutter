// ignore_for_file: unused_local_variable

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_apple_pay_component_repository.dart';
import 'package:adyen_checkout_example/utils/dialog_builder.dart';
import 'package:flutter/material.dart';

class ApplePaySessionComponentScreen extends StatelessWidget {
  const ApplePaySessionComponentScreen({
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
              _buildAdyenApplePaySessionComponent()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdyenApplePaySessionComponent() {
    final ApplePayComponentConfiguration applePayComponentConfiguration =
        ApplePayComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      countryCode: Config.countryCode,
      applePayConfiguration: _createApplePayConfiguration(),
    );

    return FutureBuilder<SessionCheckout>(
      future: repository.createSessionCheckout(applePayComponentConfiguration),
      builder: (BuildContext context, AsyncSnapshot<SessionCheckout> snapshot) {
        if (snapshot.hasData) {
          final SessionCheckout sessionCheckout = snapshot.data!;
          final paymentMethod =
              _extractPaymentMethod(sessionCheckout.paymentMethods);

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
        addressLines: ["Simon Carmiggeltstraat 6"],
        postalCode: "1011 DJ",
        city: "Amsterdam",
        country: "Netherlands",
        countryCode: "NL",
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
      onShippingContactChange: (contact, currentSummaryItems) =>
          _onShippingContactChange(contact, currentSummaryItems, today),
      onShippingMethodChange: _onShippingMethodChange,
      onCouponCodeChange: _onCouponCodeChange,
      onAuthorize: _onAuthorize,
    );
  }

  Future<ApplePayShippingContactUpdate> _onShippingContactChange(
    ApplePayContact contact,
    List<ApplePaySummaryItem> currentSummaryItems,
    DateTime today,
  ) async {
    debugPrint(
      'onShippingContactChange <- contact=$contact, '
      'currentSummaryItems=$currentSummaryItems',
    );
    final ApplePayShippingContactUpdate update;
    if (contact.postalCode == "") {
      update = ApplePayShippingContactUpdate(
        summaryItems: currentSummaryItems,
        errors: [
          ApplePayPaymentError(
            type: ApplePayPaymentErrorType.shippingAddress,
            field: ApplePayContactField.postalAddress,
            localizedDescription: "Postal code is required.",
          ),
        ],
      );
    } else {
      update = ApplePayShippingContactUpdate(
        summaryItems: _buildApplePaySummaryItems(),
        shippingMethods: _buildShippingMethods(today),
      );
    }
    debugPrint('onShippingContactChange -> $update');
    return update;
  }

  Future<ApplePayShippingMethodUpdate> _onShippingMethodChange(
    ApplePayShippingMethod method,
    List<ApplePaySummaryItem> currentSummaryItems,
  ) async {
    debugPrint(
      'onShippingMethodChange <- method=$method, '
      'currentSummaryItems=$currentSummaryItems',
    );
    final update = ApplePayShippingMethodUpdate(
      summaryItems: _buildApplePaySummaryItems(
        shippingAmount: method.amount.value,
      ),
    );
    debugPrint('onShippingMethodChange -> $update');
    return update;
  }

  Future<ApplePayCouponCodeUpdate> _onCouponCodeChange(
    String couponCode,
    List<ApplePaySummaryItem> currentSummaryItems,
  ) async {
    debugPrint(
      'onCouponCodeChange <- couponCode=$couponCode, '
      'currentSummaryItems=$currentSummaryItems',
    );
    final ApplePayCouponCodeUpdate update;
    if (couponCode.toUpperCase() != "SUMMER10") {
      update = ApplePayCouponCodeUpdate(
        summaryItems: currentSummaryItems,
        errors: [
          ApplePayPaymentError(
            type: ApplePayPaymentErrorType.couponCode,
            localizedDescription: "Use SUMMER10 for the example discount.",
          ),
        ],
      );
    } else {
      update = ApplePayCouponCodeUpdate(
        summaryItems: _buildApplePaySummaryItems(discountAmount: 1000),
      );
    }
    debugPrint('onCouponCodeChange -> $update');
    return update;
  }

  Future<ApplePayAuthorizationResult> _onAuthorize(
    ApplePayAuthorizedPayment payment,
  ) async {
    debugPrint('onAuthorize <- payment=$payment');
    final ApplePayAuthorizationResult result;
    if (payment.shippingContact?.postalCode == "") {
      result = ApplePayAuthorizationResult.failure(
        errors: [
          ApplePayPaymentError(
            type: ApplePayPaymentErrorType.shippingAddress,
            field: ApplePayContactField.postalAddress,
            localizedDescription: "Postal code is required.",
          ),
        ],
      );
    } else {
      result = const ApplePayAuthorizationResult.success();
    }
    debugPrint('onAuthorize -> $result');
    return result;
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
