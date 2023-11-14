import 'dart:convert';
import 'dart:io';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/billing_address.dart';
import 'package:adyen_checkout_example/network/models/delivery_address.dart';
import 'package:adyen_checkout_example/network/models/line_item.dart';
import 'package:adyen_checkout_example/network/models/payment_methods_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/payment_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/payment_flow_outcome_handler.dart';

class AdyenSessionsRepository {
  AdyenSessionsRepository(
      {required AdyenCheckout adyenCheckout, required Service service})
      : _service = service,
        _adyenCheckout = adyenCheckout;

  final AdyenCheckout _adyenCheckout;
  final Service _service;
  final PaymentFlowOutcomeHandler _paymentFlowOutcomeHandler =
      PaymentFlowOutcomeHandler();

  //A session should not being created from the mobile application.
  //Please provide a CheckoutSession object from your own backend.
  Future<SessionResponseNetworkModel> createSession() async {
    String returnUrl = await determineExampleReturnUrl();
    SessionRequestNetworkModel sessionRequestNetworkModel =
        SessionRequestNetworkModel(
            merchantAccount: Config.merchantAccount,
            amount: AmountNetworkModel(
              currency: Config.amount.currency,
              value: Config.amount.value,
            ),
            returnUrl: returnUrl,
            reference:
                "flutter-session-test_${DateTime.now().millisecondsSinceEpoch}",
            countryCode: Config.countryCode,
            shopperLocale: Config.shopperLocale,
            shopperReference: Config.shopperReference,
             storePaymentMethodMode: StorePaymentMethodMode
                .askForConsent.storePaymentMethodModeString,
             recurringProcessingModel:
                 RecurringProcessingModel.cardOnFile.recurringModelString,
            shopperInteraction:
                ShopperInteractionModel.ecommerce.shopperInteractionModelString,
            channel: _determineChannel(),
            telephoneNumber: "+8613012345678",
            dateOfBirth: "1996-09-04",
            socialSecurityNumber: "0108",
            deliveryAddress: DeliveryAddress(
              city: "Ankeborg",
              country: "SE",
              houseNumberOrName: "1",
              postalCode: "1234",
              street: "Stargatan",
            ),
            billingAddress: BillingAddress(
              city: "Ankeborg",
              country: "SE",
              houseNumberOrName: "1",
              postalCode: "1234",
              street: "Stargatan",
            ),
            lineItems: [
          LineItem(
            quantity: 1,
            amountExcludingTax: 331,
            taxPercentage: 2100,
            description: "Shoes",
            id: "Item #1",
            taxAmount: 69,
            amountIncludingTax: 400,
            productUrl: "URL_TO_PURCHASED_ITEM",
            imageUrl: "URL_TO_PICTURE_OF_PURCHASED_ITEM",
          ),
        ]);

    return await _service.createSession(
      sessionRequestNetworkModel,
      Config.environment,
    );
  }

  Future<String> fetchPaymentMethods() async {
    return await _service.fetchPaymentMethods(PaymentMethodsRequestNetworkModel(
      merchantAccount: Config.merchantAccount,
      countryCode: Config.countryCode,
      channel: _determineChannel(),
      shopperReference: Config.shopperReference,
    ));
  }

  Future<PaymentFlowOutcome> postPayments(String paymentComponentJson) async {
    String returnUrl = await determineExampleReturnUrl();
    PaymentsRequestData paymentsRequestData = PaymentsRequestData(
      merchantAccount: Config.merchantAccount,
      shopperReference: Config.shopperReference,
      reference: "flutter-test_${DateTime.now().millisecondsSinceEpoch}",
      returnUrl: returnUrl,
      amount: AmountNetworkModel(
        value: Config.amount.value,
        currency: Config.amount.currency,
      ),
      countryCode: Config.countryCode,
      channel: _determineChannel(),
      additionalData: AdditionalData(allow3DS2: true, executeThreeD: true),
      threeDS2RequestData: ThreeDS2RequestDataRequest(),
      threeDSAuthenticationOnly: false,
      recurringProcessingModel: RecurringProcessingModel.cardOnFile,
      shopperInteraction:
          ShopperInteractionModel.ecommerce.shopperInteractionModelString,
      lineItems: [
        LineItem(
          quantity: 1,
          amountExcludingTax: 331,
          taxPercentage: 2100,
          description: "Shoes",
          id: "Item #1",
          taxAmount: 69,
          amountIncludingTax: 400,
          productUrl: "URL_TO_PURCHASED_ITEM",
          imageUrl: "URL_TO_PICTURE_OF_PURCHASED_ITEM",
        )
      ],
    );

    Map<String, dynamic> mergedJson = <String, dynamic>{};
    mergedJson.addAll(jsonDecode(paymentComponentJson));
    mergedJson.addAll(paymentsRequestData.toJson());
    final response = await _service.postPayments(mergedJson);
    return _paymentFlowOutcomeHandler.handleResponse(response);
  }

  Future<PaymentFlowOutcome> postPaymentsDetails(
      String additionalDetails) async {
    final response =
        await _service.postPaymentsDetails(jsonDecode(additionalDetails));
    return _paymentFlowOutcomeHandler.handleResponse(response);
  }

  Future<String> determineExampleReturnUrl() async {
    if (Platform.isAndroid) {
      return await _adyenCheckout.getReturnUrl();
    } else if (Platform.isIOS) {
      return Config.iOSReturnUrl;
    } else {
      throw Exception("Unsupported platform");
    }
  }

  Future<bool> deleteStoredPaymentMethod(String storedPaymentMethodId) async {
    return await _service.deleteStoredPaymentMethod(
      storedPaymentMethodId: storedPaymentMethodId,
      merchantAccount: Config.merchantAccount,
      shopperReference: Config.shopperReference,
    );
  }

  String _determineChannel() {
    if (Platform.isAndroid) {
      return "Android";
    }

    if (Platform.isIOS) {
      return "iOS";
    }

    throw Exception("Unsupported platform");
  }
}
