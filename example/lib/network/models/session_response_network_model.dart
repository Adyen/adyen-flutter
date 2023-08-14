import 'dart:convert';

import 'package:adyen_checkout_example/network/models/amount_network_model.dart';

class SessionResponseNetworkModel {
  final AmountNetworkModel amount;
  final String countryCode;
  final DateTime expiresAt;
  final String id;
  final String merchantAccount;
  final String reference;
  final String returnUrl;
  final String sessionData;

  SessionResponseNetworkModel({
    required this.amount,
    required this.countryCode,
    required this.expiresAt,
    required this.id,
    required this.merchantAccount,
    required this.reference,
    required this.returnUrl,
    required this.sessionData,
  });

  factory SessionResponseNetworkModel.fromRawJson(String str) =>
      SessionResponseNetworkModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory SessionResponseNetworkModel.fromJson(Map<String, dynamic> json) =>
      SessionResponseNetworkModel(
        amount: AmountNetworkModel.fromJson(json["amount"]),
        countryCode: json["countryCode"],
        expiresAt: DateTime.parse(json["expiresAt"]),
        id: json["id"],
        merchantAccount: json["merchantAccount"],
        reference: json["reference"],
        returnUrl: json["returnUrl"],
        sessionData: json["sessionData"],
      );

  Map<String, dynamic> toJson() => {
        "amount": amount.toJson(),
        "countryCode": countryCode,
        "expiresAt": expiresAt.toIso8601String(),
        "id": id,
        "merchantAccount": merchantAccount,
        "reference": reference,
        "returnUrl": returnUrl,
        "sessionData": sessionData,
      };
}
