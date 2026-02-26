import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_base_repository.dart';

class AdyenGooglePayComponentRepository extends AdyenBaseRepository {
  AdyenGooglePayComponentRepository({
    required super.service,
  });

  Future<SessionCheckout> createSessionCheckout(
      GooglePayComponentConfiguration googlePayComponentConfiguration) async {
    final sessionResponse = await _fetchSession();

    return AdyenCheckout.session.setup(
      sessionResponse: SessionResponse(
        sessionResponse["id"],
        sessionResponse["sessionData"],
      ),
      checkoutConfiguration: CheckoutConfiguration(
        environment: googlePayComponentConfiguration.environment,
        clientKey: googlePayComponentConfiguration.clientKey,
        countryCode: googlePayComponentConfiguration.countryCode,
        amount: googlePayComponentConfiguration.amount,
        shopperLocale: googlePayComponentConfiguration.shopperLocale,
        analyticsOptions: googlePayComponentConfiguration.analyticsOptions,
        googlePayConfiguration: googlePayComponentConfiguration.googlePayConfiguration,
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchSession() async {
    String returnUrl = await determineBaseReturnUrl();
    returnUrl += "/adyenPayment";
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
      "channel": determineChannel(),
      "authenticationData": {
        "attemptAuthentication": "always",
        "threeDSRequestData": {
          "nativeThreeDS": "preferred",
        },
      },
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

  Future<PaymentEvent> onAdditionalDetails(
      Map<String, dynamic> additionalDetails) async {
    final response = await service.postPaymentsDetails(additionalDetails);
    return paymentEventHandler.handleResponse(jsonResponse: response);
  }
}
