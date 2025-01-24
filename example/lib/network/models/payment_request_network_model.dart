import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/line_item.dart';

class PaymentsRequestData {
  final String merchantAccount;
  final AmountNetworkModel amount;
  final String reference;
  final String? shopperReference;
  final String? countryCode;
  final String? returnUrl;
  final Map<String, dynamic>? additionalData;
  final String? shopperIP;
  final String? channel;
  final List<LineItem>? lineItems;
  final String? shopperEmail;
  final Map<String, dynamic>? threeDS2RequestData;
  final String? recurringProcessingModel;
  final String? shopperInteraction;
  final Map<String, dynamic>? authenticationData;

  PaymentsRequestData({
    required this.merchantAccount,
    required this.amount,
    required this.reference,
    this.shopperReference,
    this.countryCode,
    this.returnUrl,
    this.additionalData,
    this.shopperIP,
    this.channel,
    this.lineItems,
    this.shopperEmail,
    this.threeDS2RequestData,
    this.recurringProcessingModel,
    this.shopperInteraction,
    this.authenticationData,
  });

  Map<String, dynamic> toJson() {
    return {
      if (shopperReference != null) "shopperReference": shopperReference,
      "amount": amount.toJson(),
      if (countryCode != null) "countryCode": countryCode,
      "merchantAccount": merchantAccount,
      if (returnUrl != null) "returnUrl": returnUrl,
      if (additionalData != null) "additionalData": additionalData,
      if (shopperIP != null) "shopperIP": shopperIP,
      "reference": reference,
      if (channel != null) "channel": channel,
      if (lineItems != null)
        "lineItems": lineItems?.map((lineItem) => lineItem.toJson()).toList(),
      if (shopperEmail != null) "shopperEmail": shopperEmail,
      if (threeDS2RequestData != null)
        "threeDS2RequestData": threeDS2RequestData,
      if (recurringProcessingModel != null)
        "recurringProcessingModel": recurringProcessingModel,
      if (shopperInteraction != null) "shopperInteraction": shopperInteraction,
      if (authenticationData != null) "authenticationData": authenticationData,
    };
  }
}
