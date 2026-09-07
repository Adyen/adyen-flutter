import 'dart:convert';

import 'package:adyen_checkout_example/network/service.dart';
import 'package:http/http.dart' as http;

class NetlifyService implements Service {
  static const _baseUrl = 'https://www.mystoredemo.io/.netlify/functions';
  static const _headers = {'content-type': 'application/json'};

  Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$endpoint'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createSession(Map<String, dynamic> body) =>
      _post('sessions', body);

  @override
  Future<Map<String, dynamic>> fetchPaymentMethods(Map<String, dynamic> body) =>
      _post('paymentMethods', body);

  @override
  Future<Map<String, dynamic>> postPayments(Map<String, dynamic> body) =>
      _post('payments', body);

  @override
  Future<Map<String, dynamic>> postPaymentsDetails(Map<String, dynamic> body) =>
      _post('payments/details', body);
}
