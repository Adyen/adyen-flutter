import 'dart:convert';

import 'package:adyen_checkout_example/network/service.dart';
import 'package:http/http.dart' as http;

class NetlifyService implements Service {
  final _baseUrl = "https://www.mystoredemo.io";

  @override
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body) async {
    final http.Response response = await http.post(
      Uri.parse('$_baseUrl/.netlify/functions/sessions'),
      body: jsonEncode(body),
    );

    final String responseJsonString = utf8.decode(response.bodyBytes);
    return jsonDecode(responseJsonString);
  }

  @override
  Future<bool> deleteStoredPaymentMethod(
      String storedPaymentMethodId, Map<String, dynamic> queryParameters) {
    // TODO: implement deleteStoredPaymentMethod
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPaymentMethods(Map<String, dynamic> body) {
    // TODO: implement fetchPaymentMethods
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postCardDetails(Map<String, dynamic> body) {
    // TODO: implement postCardDetails
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postOrders(Map<String, dynamic> body) {
    // TODO: implement postOrders
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postOrdersCancel(Map<String, dynamic> body) {
    // TODO: implement postOrdersCancel
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postPaymentMethodsBalance(
      Map<String, dynamic> body) {
    // TODO: implement postPaymentMethodsBalance
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postPayments(Map<String, dynamic> body) {
    // TODO: implement postPayments
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postPaymentsDetails(Map<String, dynamic> body) {
    // TODO: implement postPaymentsDetails
    throw UnimplementedError();
  }
}
