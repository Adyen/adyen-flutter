import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_base_repository.dart';

class AdyenDropInRepository extends AdyenBaseRepository {
  AdyenDropInRepository({required super.service});

  //A session should not being created from the mobile application.
  //Please provide a CheckoutSession object from your own backend.
  Future<Map<String, dynamic>> fetchSession() async {
    String returnUrl = await determineBaseReturnUrl();
    Map<String, dynamic> sessionRequestBody = {
      "merchantAccount": Config.merchantAccount,
      "amount": {
        "currency": Config.amount.currency,
        "value": Config.amount.value,
      },
      "returnUrl": returnUrl,
      "reference":
          "flutter-session-test_${DateTime.now().millisecondsSinceEpoch}",
      "countryCode": Config.countryCode,
      "shopperLocale": Config.shopperLocale,
      "shopperReference": Config.shopperReference,
      "storePaymentMethodMode": "disabled",
      "recurringProcessingModel": "CardOnFile",
      "shopperInteraction": "Ecommerce",
      "channel": determineChannel(),
      "telephoneNumber": "+8613012345678",
      "dateOfBirth": "1996-09-04",
      "socialSecurityNumber": "0108",
      "deliveryAddress": {
        "city": "Ankeborg",
        "country": "SE",
        "houseNumberOrName": "1",
        "postalCode": "1234",
        "street": "Stargatan",
      },
      "billingAddress": {
        "city": "Ankeborg",
        "country": "SE",
        "houseNumberOrName": "1",
        "postalCode": "1234",
        "street": "Stargatan",
      },
      "lineItems": [
        {
          "quantity": 1,
          "amountExcludingTax": 331,
          "taxPercentage": 2100,
          "description": "Shoes",
          "id": "Item #1",
          "taxAmount": 69,
          "amountIncludingTax": 400,
          "productUrl": "URL_TO_PURCHASED_ITEM",
          "imageUrl": "URL_TO_PICTURE_OF_PURCHASED_ITEM",
        },
      ],
      "installmentOptions": {
        "card": {
          "values": [1, 2, 3, 6],
          "plans": ["with_interest"]
        },
        "visa": {
          "values": [1, 2, 3, 4, 5, 12],
          "plans": ["regular", "revolving"]
        },
        "mc": {
          "values": [1, 2, 3, 4, 5, 12],
          "plans": ["regular", "revolving"]
        }
      },
    };

    return await service.createSession(sessionRequestBody);
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
    Map<String, dynamic> paymentsRequestBody = {
      "merchantAccount": Config.merchantAccount,
      "shopperReference": Config.shopperReference,
      "reference": "flutter-test_${DateTime.now().millisecondsSinceEpoch}",
      "returnUrl": returnUrl,
      "amount": {
        "value": Config.amount.value,
        "currency": Config.amount.currency,
      },
      "countryCode": Config.countryCode,
      "channel": determineChannel(),
      "recurringProcessingModel": "CardOnFile",
      "authenticationData": {
        "attemptAuthentication": "always",
        "threeDSRequestData": {
          "nativeThreeDS": "preferred",
        },
      },
    };

    // This will override any already existing fields in paymentsRequestData
    paymentsRequestBody.addAll(data);
    final response = await service.postPayments(paymentsRequestBody);
    return await _evaluatePaymentsResponse(response);
  }

  Future<PaymentEvent> _evaluatePaymentsResponse(
      Map<String, dynamic> response) async {
    if (_hasOrderWithRemainingAmount(response)) {
      final Map<String, dynamic> updatedPaymentMethodsJson =
          await fetchPaymentMethods(
        orderResponse: {
          "pspReference": response["order"]["pspReference"],
          "orderData": response["order"]["orderData"],
        },
      );
      return paymentEventHandler.handleResponse(
        jsonResponse: response,
        updatedPaymentMethodsJson: updatedPaymentMethodsJson,
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

  Future<Map<String, dynamic>> onCheckBalance({
    required Map<String, dynamic> balanceCheckRequestBody,
  }) async {
    balanceCheckRequestBody.addAll({"merchantAccount": Config.merchantAccount});
    return service.postPaymentMethodsBalance(balanceCheckRequestBody);
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

  Future<OrderCancelResult> onCancelOrder({
    required bool shouldUpdatePaymentMethods,
    required Map<String, dynamic> order,
  }) async {
    final orderCancelRequestBody = <String, dynamic>{
      "merchantAccount": Config.merchantAccount,
      "order": order,
    };
    final Map<String, dynamic> cancelResponse =
        await service.postOrdersCancel(orderCancelRequestBody);
    final OrderCancelResult orderCancelResult =
        OrderCancelResult(orderCancelResponseBody: cancelResponse);
    if (shouldUpdatePaymentMethods == true) {
      orderCancelResult.updatedPaymentMethodsResponseBody =
          await fetchPaymentMethods();
    }

    return orderCancelResult;
  }

  bool _hasOrderWithRemainingAmount(jsonResponse) {
    if (jsonResponse.containsKey("order")) {
      final remainingAmount = jsonResponse["order"]["remainingAmount"]["value"];
      return remainingAmount > 0;
    }
    return false;
  }
}
