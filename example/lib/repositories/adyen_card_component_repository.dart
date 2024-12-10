import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/payment_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/repositories/adyen_base_repository.dart';

class AdyenCardComponentRepository extends AdyenBaseRepository {
  AdyenCardComponentRepository({
    required super.service,
  });

  Future<SessionResponseNetworkModel> fetchSession() async {
    String returnUrl = await determineBaseReturnUrl();
    returnUrl += "/adyenPayment";
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
          StorePaymentMethodMode.enabled.storePaymentMethodModeString,
      recurringProcessingModel:
          RecurringProcessingModel.cardOnFile.recurringModelString,
      shopperInteraction:
          ShopperInteractionModel.ecommerce.shopperInteractionModelString,
      channel: determineChannel(),
    );

    return await service.createSession(
      sessionRequestNetworkModel,
      Config.environment,
    );
  }

  Future<Map<String, dynamic>> fetchPaymentMethods() async {
    return await service.fetchPaymentMethods(<String, dynamic>{
      "merchantAccount": Config.merchantAccount,
      "countryCode": Config.countryCode,
      "channel": determineChannel(),
      "shopperReference": Config.shopperReference,
    });
  }

  Future<PaymentEvent> onSubmit(
    Map<String, dynamic> data, [
    Map<String, dynamic>? extra,
  ]) async {
    String returnUrl = await determineBaseReturnUrl();
    returnUrl += "/adyenPayment";
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
      recurringProcessingModel: RecurringProcessingModel.cardOnFile,
      shopperInteraction:
          ShopperInteractionModel.ecommerce.shopperInteractionModelString,
      authenticationData: {
        "threeDSRequestData": {
          "nativeThreeDS": "preferred",
        },
      },
    );

    Map<String, dynamic> mergedJson = <String, dynamic>{};
    mergedJson.addAll(data);
    mergedJson.addAll(paymentsRequestData.toJson());
    final response = await service.postPayments(mergedJson);
    return paymentEventHandler.handleResponse(jsonResponse: response);
  }

  Future<PaymentEvent> onAdditionalDetails(
      Map<String, dynamic> additionalDetails) async {
    final response = await service.postPaymentsDetails(additionalDetails);
    return paymentEventHandler.handleResponse(jsonResponse: response);
  }
}
