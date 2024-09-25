import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/payment_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/repositories/adyen_base_repository.dart';

class AdyenApplePayComponentRepository extends AdyenBaseRepository {
  AdyenApplePayComponentRepository({
    required super.service,
  });

  Future<SessionCheckout> createSessionCheckout(
      ApplePayComponentConfiguration applePayComponentConfiguration) async {
    final sessionResponse = await fetchSession();
    return await AdyenCheckout.session.create(
      sessionId: sessionResponse.id,
      sessionData: sessionResponse.sessionData,
      configuration: applePayComponentConfiguration,
    );
  }

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
      channel: determineChannel(),
      authenticationData: {
        "attemptAuthentication": "always",
        "threeDSRequestData": {
          "nativeThreeDS": "preferred",
        },
      },
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
    returnUrl += "/applePay";
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
    return paymentEventHandler.handleResponse(jsonResponse: response);
  }

  Future<PaymentEvent> onAdditionalDetailsMock(
          Map<String, dynamic> additionalDetailsJson) =>
      Future.error(
          "Additional details call is not required for the Apple Pay component.");
}
