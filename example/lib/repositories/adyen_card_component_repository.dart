import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_base_repository.dart';

class AdyenCardComponentRepository extends AdyenBaseRepository {
  AdyenCardComponentRepository({
    required super.service,
  });

  Future<SessionCheckout> createSessionCheckout(
      CardComponentConfiguration cardComponentConfiguration) async {
    final sessionResponse = await _fetchSession();

    return AdyenCheckout.session.setup(
      sessionResponse: SessionResponse(
        sessionResponse["id"],
        sessionResponse["sessionData"],
      ),
      checkoutConfiguration: CheckoutConfiguration(
        environment: cardComponentConfiguration.environment,
        clientKey: cardComponentConfiguration.clientKey,
        countryCode: cardComponentConfiguration.countryCode,
        amount: cardComponentConfiguration.amount,
        shopperLocale: cardComponentConfiguration.shopperLocale,
        analyticsOptions: cardComponentConfiguration.analyticsOptions,
        cardConfiguration: cardComponentConfiguration.cardConfiguration,
        threeDS2Configuration: cardComponentConfiguration.threeDS2Configuration,
      ),
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
      "countryCode": Config.countryCode,
      "shopperLocale": Config.shopperLocale,
      "shopperReference": Config.shopperReference,
      "channel": determineChannel(),
      "storePaymentMethodMode": "disabled", //enabled, disabled, askForConsent
      "recurringProcessingModel": "CardOnFile", // Subscription
      "shopperInteraction": "Ecommerce",
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
    returnUrl += "/adyenPayment";

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
        "threeDSRequestData": {
          "nativeThreeDS": "preferred",
        },
      },
    };

    paymentsRequestBody.addAll(data);
    final response = await service.postPayments(paymentsRequestBody);
    return paymentEventHandler.handleResponse(jsonResponse: response);
  }

  Future<PaymentEvent> onAdditionalDetails(
      Map<String, dynamic> additionalDetails) async {
    final response = await service.postPaymentsDetails(additionalDetails);
    return paymentEventHandler.handleResponse(jsonResponse: response);
  }
}
