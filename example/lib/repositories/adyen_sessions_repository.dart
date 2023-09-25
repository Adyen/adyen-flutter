import 'dart:convert';
import 'dart:io';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/payment_methods_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/payment_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:adyen_checkout_example/repositories/drop_in_outcome_handler.dart';

class AdyenSessionsRepository {
  AdyenSessionsRepository(
      {required AdyenCheckout adyenCheckout, required Service service})
      : _service = service,
        _adyenCheckout = adyenCheckout;

  final AdyenCheckout _adyenCheckout;
  final Service _service;
  final DropInOutcomeHandler _dropInOutcomeHandler = DropInOutcomeHandler();

  //A session should not being created from the mobile application.
  //Please provide a CheckoutSession object from your own backend.
  Future<Session> createSession(Amount amount, Environment environment) async {
    String returnUrl = await determineExampleReturnUrl();
    SessionRequestNetworkModel sessionRequestNetworkModel =
        SessionRequestNetworkModel(
      merchantAccount: Config.merchantAccount,
      amount: AmountNetworkModel(
        currency: amount.currency,
        value: amount.value,
      ),
      returnUrl: returnUrl,
      reference:
          "flutter-session-test_${DateTime.now().millisecondsSinceEpoch}",
      countryCode: Config.countryCode,
      shopperReference: Config.shopperReference,
      storePaymentMethodMode:
          StorePaymentMethodMode.enabled.storePaymentMethodModeString,
      recurringProcessingModel:
          RecurringProcessingModel.cardOnFile.recurringModelString,
    );

    SessionResponseNetworkModel sessionResponseNetworkModel =
        await _service.createSession(sessionRequestNetworkModel, environment);

    return Session(
      id: sessionResponseNetworkModel.id,
      sessionData: sessionResponseNetworkModel.sessionData,
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

  Future<DropInOutcome> postPayments(String paymentComponentJson) async {
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
      lineItems: [],
    );

    Map<String, dynamic> mergedJson = <String, dynamic>{};
    mergedJson.addAll(jsonDecode(paymentComponentJson));
    mergedJson.addAll(paymentsRequestData.toJson());
    final response = await _service.postPayments(mergedJson);
    return _dropInOutcomeHandler.handleResponse(response);
  }

  Future<DropInOutcome> postPaymentsDetails(String additionalDetails) async {
    final response =
        await _service.postPaymentsDetails(jsonDecode(additionalDetails));
    return _dropInOutcomeHandler.handleResponse(response);
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
