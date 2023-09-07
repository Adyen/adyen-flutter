import 'dart:convert';

import 'package:adyen_checkout_example/network/models/amount_network_model.dart';

class PaymentMethodsRequestNetworkModel {
  final String merchantAccount;
  final AmountNetworkModel? amount;
  final String? channel;
  final String? countryCode;
  final String? shopperReference;

  PaymentMethodsRequestNetworkModel({
    required this.merchantAccount,
    this.amount,
    this.channel,
    this.countryCode,
    this.shopperReference,
  });

  String toRawJson() {
    return json.encode(toJson());
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = <String, dynamic>{};
    json.addAll({"merchantAccount": merchantAccount});

    if (amount != null) {
      json.addAll({"amount": amount?.toJson()});
    }
    if (channel != null) {
      json.addAll({"channel": channel});
    }
    if (countryCode != null) {
      json.addAll({"countryCode": countryCode});
    }
    if (shopperReference != null) {
      json.addAll({"shopperReference": shopperReference});
    }
    return json;
  }
}
