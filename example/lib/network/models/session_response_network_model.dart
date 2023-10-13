import 'dart:convert';

import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/billing_address.dart';
import 'package:adyen_checkout_example/network/models/delivery_address.dart';
import 'package:adyen_checkout_example/network/models/line_item.dart';

class SessionResponseNetworkModel {
  final AmountNetworkModel amount;
  final String countryCode;
  final DateTime expiresAt;
  final String id;
  final String merchantAccount;
  final String reference;
  final String returnUrl;
  final String sessionData;
  final String? shopperLocale;
  final String? shopperReference;
  final String? storePaymentMethodMode;
  final String? recurringProcessingModel;
  final String? telephoneNumber;
  final String? dateOfBirth;
  final String? socialSecurityNumber;
  final DeliveryAddress? deliveryAddress;
  final BillingAddress? billingAddress;
  final List<LineItem>? lineItems;

  SessionResponseNetworkModel({
    required this.amount,
    required this.countryCode,
    required this.expiresAt,
    required this.id,
    required this.merchantAccount,
    required this.reference,
    required this.returnUrl,
    required this.sessionData,
    this.shopperLocale,
    this.shopperReference,
    this.storePaymentMethodMode,
    this.recurringProcessingModel,
    this.telephoneNumber,
    this.dateOfBirth,
    this.socialSecurityNumber,
    this.deliveryAddress,
    this.billingAddress,
    this.lineItems,
  });

  factory SessionResponseNetworkModel.fromRawJson(String str) =>
      SessionResponseNetworkModel.fromJson(json.decode(str));

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
        shopperLocale: json["shopperLocale"],
        shopperReference: json["shopperReference"],
        storePaymentMethodMode: json["storePaymentMethodMode"],
        recurringProcessingModel: json["recurringProcessingModel"],
        telephoneNumber: json["telephoneNumber"],
        dateOfBirth: json["dateOfBirth"],
        socialSecurityNumber: json["socialSecurityNumber"],
        deliveryAddress: json["deliveryAddress"] != null
            ? DeliveryAddress.fromJson(json["deliveryAddress"])
            : null,
        billingAddress: json["billingAddress"] != null
            ? BillingAddress.fromJson(json["billingAddress"])
            : null,
        lineItems: List<LineItem>.from(
            json["lineItems"].map((model) => LineItem.fromJson(model))),
      );
}
