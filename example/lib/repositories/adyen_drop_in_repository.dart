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

  Future<Map<String, dynamic>> fetchPaymentMethods() async {
    return await service.fetchPaymentMethods(PaymentMethodsRequestNetworkModel(
      amount: AmountNetworkModel(
        currency: Config.amount.currency,
        value: Config.amount.value,
      ),
      merchantAccount: Config.merchantAccount,
      countryCode: Config.countryCode,
      channel: determineChannel(),
      shopperReference: Config.shopperReference,
    ));
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
    mergedJson.addAll(data);
    mergedJson.addAll(paymentsRequestData.toJson());
    final response = await service.postPayments(mergedJson);
    return paymentEventHandler.handleResponse(response);
  }

  Future<PaymentEvent> onAdditionalDetails(
      Map<String, dynamic> additionalDetails) async {
    final response = await service.postPaymentsDetails(additionalDetails);
    return paymentEventHandler.handleResponse(response);
  }

  Future<bool> deleteStoredPaymentMethod(String storedPaymentMethodId) async {
    return await service.deleteStoredPaymentMethod(
      storedPaymentMethodId: storedPaymentMethodId,
      merchantAccount: Config.merchantAccount,
      shopperReference: Config.shopperReference,
    );
  }
}
