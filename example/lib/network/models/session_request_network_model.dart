import 'dart:convert';

import 'package:adyen_checkout_example/network/models/amount_network_model.dart';
import 'package:adyen_checkout_example/network/models/billing_address.dart';
import 'package:adyen_checkout_example/network/models/delivery_address.dart';
import 'package:adyen_checkout_example/network/models/line_item.dart';

class SessionRequestNetworkModel {
  final String merchantAccount;
  final AmountNetworkModel amount;
  final String returnUrl;
  final String reference;
  final String countryCode;
  final String? shopperLocale;
  final String? shopperReference;
  final String? storePaymentMethodMode;
  final String? recurringProcessingModel;
  final String? channel;
  final String? telephoneNumber;
  final String? dateOfBirth;
  final String? socialSecurityNumber;
  final DeliveryAddress? deliveryAddress;
  final BillingAddress? billingAddress;
  final List<LineItem>? lineItems;

  SessionRequestNetworkModel({
    required this.merchantAccount,
    required this.amount,
    required this.returnUrl,
    required this.reference,
    required this.countryCode,
    this.shopperLocale,
    this.shopperReference,
    this.storePaymentMethodMode,
    this.recurringProcessingModel,
    this.channel,
    this.telephoneNumber,
    this.dateOfBirth,
    this.socialSecurityNumber,
    this.deliveryAddress,
    this.billingAddress,
    this.lineItems,
  });

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['merchantAccount'] = merchantAccount;
    data['amount'] = amount.toJson();
    data['returnUrl'] = returnUrl;
    data['reference'] = reference;
    data['countryCode'] = countryCode;
    data['shopperLocale'] = shopperLocale;
    data['shopperReference'] = shopperReference;
    data['storePaymentMethodMode'] = storePaymentMethodMode;
    data['recurringProcessingModel'] = recurringProcessingModel;
    data['channel'] = channel;
    data['telephoneNumber'] = telephoneNumber;
    data['dateOfBirth'] = dateOfBirth;
    data['socialSecurityNumber'] = socialSecurityNumber;
    data['billingAddress'] = billingAddress?.toJson();
    data['deliveryAddress'] = deliveryAddress?.toJson();
    data['lineItems'] =
        lineItems?.map((lineItem) => lineItem.toJson()).toList();
    return data;
  }
}

enum StorePaymentMethodMode {
  disabled,
  askForConsent,
  enabled,
}

enum RecurringProcessingModel {
  subscription,
  cardOnFile,
  unscheduledCardOnFile
}

extension StorePaymentMethodModeExtension on StorePaymentMethodMode {
  String get storePaymentMethodModeString {
    switch (this) {
      case StorePaymentMethodMode.disabled:
        return "disabled";
      case StorePaymentMethodMode.askForConsent:
        return "askForConsent";
      case StorePaymentMethodMode.enabled:
        return "enabled";
    }
  }
}

extension RecurringProcessingModelExtension on RecurringProcessingModel {
  String get recurringModelString {
    switch (this) {
      case RecurringProcessingModel.subscription:
        return 'Subscription';
      case RecurringProcessingModel.cardOnFile:
        return 'CardOnFile';
      case RecurringProcessingModel.unscheduledCardOnFile:
        return 'UnscheduledCardOnFile';
    }
  }
}
