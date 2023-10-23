import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/line_item.dart';
import 'package:adyen_checkout_example/network/models/session_request_network_model.dart';

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
  final List<LineItem>? lineItems;
  final String? shopperEmail;
  final ThreeDS2RequestDataRequest? threeDS2RequestData;
  final RecurringProcessingModel? recurringProcessingModel;
  final String? shopperInteraction;

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
    this.shopperInteraction,
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
        "lineItems": lineItems?.map((lineItem) => lineItem.toJson()).toList(),
      if (shopperEmail != null) "shopperEmail": shopperEmail,
      if (threeDS2RequestData != null)
        "threeDS2RequestData": threeDS2RequestData?.toJson(),
      if (recurringProcessingModel != null)
        "recurringProcessingModel": recurringProcessingModel?.recurringModelString,
      if (shopperInteraction != null) "shopperInteraction" : shopperInteraction
    };
  }
}

class AdditionalData {
  final bool allow3DS2;
  final bool executeThreeD;

  AdditionalData({
    required this.allow3DS2,
    required this.executeThreeD,
  });

  Map<String, dynamic> toJson() {
    return {
      'allow3DS2': allow3DS2,
      'executeThreeD': executeThreeD,
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

