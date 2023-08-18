import 'dart:convert';
import 'dart:io';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/platform_api.g.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/payment_methods_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/payment_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/network/service.dart';

class AdyenSessionsRepository {
  AdyenSessionsRepository(
      {required AdyenCheckout adyenCheckout, required Service service})
      : _service = service,
        _adyenCheckout = adyenCheckout;

  final AdyenCheckout _adyenCheckout;
  final Service _service;

  //A session should not being created from the mobile application.
  //Please provide a CheckoutSession object from your own backend.
  Future<SessionModel> createSession(
      Amount amount, Environment environment) async {
    String returnUrl = await _determineExampleReturnUrl();
    SessionRequestNetworkModel sessionRequestNetworkModel =
        SessionRequestNetworkModel(
      merchantAccount: Config.merchantAccount,
      amount: AmountNetworkModel(
        currency: amount.currency,
        value: amount.value,
      ),
      returnUrl: returnUrl,
      reference: Config.shopperReference,
      countryCode: Config.countryCode,
    );

    SessionResponseNetworkModel sessionResponseNetworkModel =
        await _service.createSession(sessionRequestNetworkModel, environment);

    return SessionModel(
      id: sessionResponseNetworkModel.id,
      sessionData: sessionResponseNetworkModel.sessionData,
    );
  }

  Future<String> fetchPaymentMethods() async {
    return await _service.fetchPaymentMethods(PaymentMethodsRequestNetworkModel(
        merchantAccount: Config.merchantAccount));
  }

  Future<Map<String, dynamic>> postPayments(String paymentComponentJson) async {
    String returnUrl = await _determineExampleReturnUrl();
    PaymentsRequestData paymentsRequestData = PaymentsRequestData(
      merchantAccount: Config.merchantAccount,
      reference: Config.shopperReference,
      returnUrl: returnUrl,
      amount: AmountNetworkModel(
        value: Config.amount.value,
        currency: Config.amount.currency,
      ),
    );

    Map<String, dynamic> mergedJson = <String, dynamic>{};
    mergedJson.addAll(json.decode(paymentComponentJson));
    mergedJson.addAll(paymentsRequestData.toJson());
    return await _service.postPayments(mergedJson);
  }

  Future<Map<String, dynamic>> postPaymentsDetails(String additionalDetails) async {
    return await _service.postPaymentsDetails(json.decode(additionalDetails));
  }

  Future<String> _determineExampleReturnUrl() async {
    if (Platform.isAndroid) {
      return await _adyenCheckout.getReturnUrl();
    } else if (Platform.isIOS) {
      return Config.iOSReturnUrl;
    } else {
      throw Exception("Unsupported platform");
    }
  }
}
