import 'dart:convert';

import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/network/service.dart';
import 'package:http/http.dart' as http;

class CheckoutService implements Service {
  Map<String, String> get _headers => {
        'content-type': 'application/json',
        'x-API-key': Config.xApiKey,
      };

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.https(Config.baseUrl, '/${Config.apiVersion}/$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
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
