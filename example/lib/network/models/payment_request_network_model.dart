import 'dart:convert';

import 'package:adyen_checkout_example/network/models/amount_network_model.dart';

class PaymentsRequestNetworkModel {
  final Map<String, dynamic> paymentComponentData;
  final PaymentsRequestData requestData;

  PaymentsRequestNetworkModel({
    required this.paymentComponentData,
    required this.requestData,
  });

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() {
    return {
      'paymentComponentData': paymentComponentData,
      'requestData': requestData.toJson(),
    };
  }
}

class PaymentsRequestData {
  final String merchantAccount;
  final AmountNetworkModel amount;
  final String reference;
  final String? shopperReference;
  final String? countryCode;
  final String? returnUrl;
  final AdditionalData? additionalData;
  final bool? threeDSAuthenticationOnly;
  final String? shopperIP;
  final String? channel;
  final List<Item>? lineItems;
  final String? shopperEmail;
  final ThreeDS2RequestDataRequest? threeDS2RequestData;
  final String? recurringProcessingModel;

  PaymentsRequestData({
    required this.merchantAccount,
    required this.amount,
    required this.reference,
    this.shopperReference,
    this.countryCode,
    this.returnUrl,
    this.additionalData,
    this.threeDSAuthenticationOnly,
    this.shopperIP,
    this.channel,
    this.lineItems,
    this.shopperEmail,
    this.threeDS2RequestData,
    this.recurringProcessingModel,
  });

  Map<String, dynamic> toJson() {
    return {
      if (shopperReference != null) "shopperReference": shopperReference,
      "amount": amount.toJson(),
      if (countryCode != null) "countryCode": countryCode,
      "merchantAccount": merchantAccount,
      if (returnUrl != null) "returnUrl": returnUrl,
      if (additionalData != null) "additionalData": additionalData?.toJson(),
      if (threeDSAuthenticationOnly != null)
        "threeDSAuthenticationOnly": threeDSAuthenticationOnly,
      if (shopperIP != null) "shopperIP": shopperIP,
      "reference": reference,
      if (channel != null) "channel": channel,
      if (lineItems != null)
        "lineItems": lineItems?.map((item) => item.toJson()).toList(),
      if (shopperEmail != null) "shopperEmail": shopperEmail,
      if (threeDS2RequestData != null)
        "threeDS2RequestData": threeDS2RequestData?.toJson(),
      if (recurringProcessingModel != null)
        "recurringProcessingModel": recurringProcessingModel,
    };
  }
}

class AdditionalData {
  final String allow3DS2;
  final String executeThreeD;

  AdditionalData({
    this.allow3DS2 = 'false',
    this.executeThreeD = 'false',
  });

  Map<String, dynamic> toJson() {
    return {
      'allow3DS2': allow3DS2,
      'executeThreeD': executeThreeD,
    };
  }
}

class Item {
  final int quantity;
  final int amountExcludingTax;
  final int taxPercentage;
  final String description;
  final String id;
  final int amountIncludingTax;
  final String taxCategory;

  Item({
    required this.quantity,
    required this.amountExcludingTax,
    required this.taxPercentage,
    required this.description,
    required this.id,
    required this.amountIncludingTax,
    required this.taxCategory,
  });

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'amountExcludingTax': amountExcludingTax,
      'taxPercentage': taxPercentage,
      'description': description,
      'id': id,
      'amountIncludingTax': amountIncludingTax,
      'taxCategory': taxCategory,
    };
  }
}

class ThreeDS2RequestDataRequest {
  final String deviceChannel;
  final String challengeIndicator;

  ThreeDS2RequestDataRequest({
    this.deviceChannel = 'app',
    this.challengeIndicator = 'requestChallenge',
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceChannel': deviceChannel,
      'challengeIndicator': challengeIndicator,
    };
  }
}
