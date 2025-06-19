// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:http/http.dart' as http;

class CheckoutService implements Service {
  @override
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/sessions"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> fetchPaymentMethods(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/paymentMethods"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> postPayments(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/payments"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    print("PspReference: ${response.headers["pspreference"]}");
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> postPaymentsDetails(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/payments/details"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  @override
  Future<bool> deleteStoredPaymentMethod(
    String storedPaymentMethodId,
    Map<String, dynamic> queryParameters,
  ) async {
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

  @override
  Future<Map<String, dynamic>> postPaymentMethodsBalance(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/paymentMethods/balance"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> postOrders(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/orders"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> postOrdersCancel(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/orders/cancel"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  @override
  Future<Map<String, dynamic>> postCardDetails(
      Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, "/${Config.apiVersion}/cardDetails"),
      headers: _createHeaders(),
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  Map<String, String> _createHeaders() => {
        "content-type": "application/json",
        "x-API-key": Config.xApiKey,
      };
}
