import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_base_repository.dart';

class AdyenApplePayComponentRepository extends AdyenBaseRepository {
  AdyenApplePayComponentRepository({
    required super.service,
  });

  Future<SessionCheckout> createSessionCheckout(
      ApplePayComponentConfiguration applePayComponentConfiguration) async {
    final sessionResponse = await _fetchSession();
    return await AdyenCheckout.session.create(
      sessionId: sessionResponse["id"],
      sessionData: sessionResponse["sessionData"],
      configuration: applePayComponentConfiguration,
    );
  }

  Future<Map<String, dynamic>> _fetchSession() async {
    String returnUrl = await determineBaseReturnUrl();
    returnUrl += "/adyenPayment";
    Map<String, dynamic> sessionRequestBody = <String, dynamic>{
      "merchantAccount": Config.merchantAccount,
      "amount": {
        "currency": Config.amount.currency,
        "value": Config.amount.value,
      },
      "returnUrl": returnUrl,
      "reference":
          "flutter-session-test_${DateTime.now().millisecondsSinceEpoch}",
      "shopperReference": Config.shopperReference,
      "channel": determineChannel(),
    };

    return await service.createSession(sessionRequestBody);
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
      "shopperInteraction": "Ecommerce",
      "authenticationData": {
        "attemptAuthentication": "always",
        "threeDSRequestData": {
          "nativeThreeDS": "preferred",
        },
      },
    };

    paymentsRequestBody.addAll(data);
    final response = await service.postPayments(paymentsRequestBody);
    return paymentEventHandler.handleResponse(jsonResponse: response);
  }

  Future<PaymentEvent> onAdditionalDetailsMock(
          Map<String, dynamic> additionalDetailsJson) =>
      Future.error(
          "Additional details call is not required for the Apple Pay component.");
}
