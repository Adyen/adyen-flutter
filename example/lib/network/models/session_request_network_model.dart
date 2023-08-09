import 'dart:convert';

import 'package:adyen_checkout_example/network/models/amount_network_model.dart';

class SessionRequestNetworkModel {
  final String merchantAccount;
  final AmountNetworkModel amount;
  final String returnUrl;
  final String reference;
  final String countryCode;

  SessionRequestNetworkModel({
    required this.merchantAccount,
    required this.amount,
    required this.returnUrl,
    required this.reference,
    required this.countryCode,
  });

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['merchantAccount'] = merchantAccount;
    data['amount'] = amount.toJson();
    data['returnUrl'] = returnUrl;
    data['reference'] = reference;
    data['countryCode'] = countryCode;
    return data;
  }
}
