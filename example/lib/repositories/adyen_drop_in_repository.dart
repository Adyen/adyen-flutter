import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/billing_address.dart';
import 'package:adyen_checkout_example/network/models/delivery_address.dart';
import 'package:adyen_checkout_example/network/models/line_item.dart';
import 'package:adyen_checkout_example/network/models/payment_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/repositories/adyen_base_repository.dart';

class AdyenDropInRepository extends AdyenBaseRepository {
  AdyenDropInRepository({required super.service});

  //A session should not being created from the mobile application.
  //Please provide a CheckoutSession object from your own backend.
  Future<SessionResponseNetworkModel> fetchSession() async {
    String returnUrl = await determineBaseReturnUrl();
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
            storePaymentMethodMode:
                StorePaymentMethodMode.disabled.storePaymentMethodModeString,
            recurringProcessingModel:
                RecurringProcessingModel.cardOnFile.recurringModelString,
            shopperInteraction:
                ShopperInteractionModel.ecommerce.shopperInteractionModelString,
            channel: determineChannel(),
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

    return await service.createSession(
      sessionRequestNetworkModel,
      Config.environment,
    );
  }

  Future<Map<String, dynamic>> fetchPaymentMethods({
    Map<String, dynamic>? orderResponse,
  }) async {
    final requestBody = <String, dynamic>{
      "amount": {
        "value": Config.amount.value,
        "currency": Config.amount.currency
      },
      "merchantAccount": Config.merchantAccount,
      "countryCode": Config.countryCode,
      "channel": determineChannel(),
      "shopperReference": Config.shopperReference,
    };

    //Add order for partial payments support
    if (orderResponse != null) {
      requestBody.addAll({"order": orderResponse});
    }

    return await service.fetchPaymentMethods(requestBody);
  }

  Future<PaymentEvent> onSubmit(
    Map<String, dynamic> data, [
    Map<String, dynamic>? extra,
  ]) async {
    String returnUrl = await determineBaseReturnUrl();
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
      channel: determineChannel(),
      authenticationData: {
        "attemptAuthentication": "always",
        "threeDSRequestData": {
          "nativeThreeDS": "preferred",
        },
      },
    );

    Map<String, dynamic> mergedJson = <String, dynamic>{};
    mergedJson.addAll(paymentsRequestData.toJson());
    // This will override any already existing fields in paymentsRequestData
    mergedJson.addAll(data);
    final response = await service.postPayments(mergedJson);
    final paymentEvent = await _evaluatePaymentsResponse(response);
    return paymentEvent;
  }

  Future<PaymentEvent> _evaluatePaymentsResponse(
      Map<String, dynamic> response) async {
    if (_hasOrderWithRemainingAmount(response)) {
      final Map<String, dynamic> updatedPaymentMethods =
          await fetchPaymentMethods(
        orderResponse: {
          "pspReference": response["order"]["pspReference"],
          "orderData": response["order"]["orderData"],
        },
      );
      return paymentEventHandler.handleResponse(
        jsonResponse: response,
        updatedPaymentMethods: updatedPaymentMethods,
      );
    } else {
      return paymentEventHandler.handleResponse(jsonResponse: response);
    }
  }

  Future<PaymentEvent> onAdditionalDetails(
      Map<String, dynamic> additionalDetails) async {
    final Map<String, dynamic> response =
        await service.postPaymentsDetails(additionalDetails);
    return paymentEventHandler.handleResponse(jsonResponse: response);
  }

  Future<bool> deleteStoredPaymentMethod(String storedPaymentMethodId) async {
    final Map<String, dynamic> queryParameters = <String, dynamic>{
      'merchantAccount': Config.merchantAccount,
      'shopperReference': Config.shopperReference,
    };

    return await service.deleteStoredPaymentMethod(
      storedPaymentMethodId,
      queryParameters,
    );
  }

  Future<Map<String, dynamic>> onCheckBalance(
      Map<String, dynamic> balanceRequestBody) async {
    balanceRequestBody.addAll({"merchantAccount": Config.merchantAccount});
    return service.postPaymentMethodsBalance(balanceRequestBody);
  }

  Future<Map<String, dynamic>> onRequestOrder() async {
    final Map<String, dynamic> orderRequestBody = <String, dynamic>{
      "reference": "flutter-test_${DateTime.now().millisecondsSinceEpoch}",
      "amount": {
        "value": Config.amount.value,
        "currency": Config.amount.currency
      },
      "merchantAccount": Config.merchantAccount,
    };
    return service.postOrders(orderRequestBody);
  }

  Future<OrderCancelResponse> onCancelOrder(
    bool shouldUpdatePaymentMethods,
    Map<String, dynamic> order,
  ) async {
    final orderCancelRequestBody = <String, dynamic>{
      "merchantAccount": Config.merchantAccount,
      "order": order,
    };
    final Map<String, dynamic> orderCancelResponseBody =
        await service.postOrdersCancel(orderCancelRequestBody);
    final OrderCancelResponse orderCancelResponse =
        OrderCancelResponse(orderCancelResponseBody: orderCancelResponseBody);
    if (shouldUpdatePaymentMethods == true) {
      final paymentMethods = await fetchPaymentMethods();
      orderCancelResponse.updatedPaymentMethods = paymentMethods;
    }

    return orderCancelResponse;
  }

  bool _hasOrderWithRemainingAmount(jsonResponse) {
    if (jsonResponse.containsKey("order")) {
      final remainingAmount = jsonResponse["order"]["remainingAmount"]["value"];
      return remainingAmount > 0;
    }
    return false;
  }
}
