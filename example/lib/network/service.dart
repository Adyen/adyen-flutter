import 'dart:convert';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/models/payment_methods_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';
import 'package:adyen_checkout_example/network/models/session_response_network_model.dart';
import 'package:http/http.dart' as http;

class Service {
  Future<SessionResponseNetworkModel> createSession(
      SessionRequestNetworkModel sessionRequestNetworkModel,
      Environment environment) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/sessions"),
      headers: _createHeaders(),
      body: sessionRequestNetworkModel.toRawJson(),
    );
    print("PspReference: ${response.headers["pspreference"]}");
    return SessionResponseNetworkModel.fromRawJson(response.body);
  }

  Future<String> fetchPaymentMethods(
      PaymentMethodsRequestNetworkModel
          paymentMethodsRequestNetworkModel) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/paymentMethods"),
      headers: _createHeaders(),
      body: paymentMethodsRequestNetworkModel.toRawJson(),
    );
    return response.body;
  }

  Future<Map<String, dynamic>> postPayments(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/payments"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    print("PspReference: ${response.headers["pspreference"]}");
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> postPaymentsDetails(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/payments/details"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  Future<bool> deleteStoredPaymentMethod({
    required String storedPaymentMethodId,
    required String merchantAccount,
    required String shopperReference,
  }) async {
    final queryParameters = {
      'merchantAccount': merchantAccount,
      'shopperReference': shopperReference,
    };

    final response = await http.delete(
      Uri.https(
        Config.baseUrl,
        "/${Config.apiVersion}/storedPaymentMethods/$storedPaymentMethodId",
        queryParameters,
      ),
      headers: _createHeaders(),
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      return false;
    }
  }

  Map<String, String> _createHeaders() => {
        "content-type": "application/json",
        "x-API-key": Config.xApiKey,
      };
}
