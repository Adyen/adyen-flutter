import 'dart:convert';

import 'package:adyen_checkout_example/network/models/amount_network_model.dart';

class SessionRequestNetworkModel {
  final String merchantAccount;
  final AmountNetworkModel amount;
  final String returnUrl;
  final String reference;
  final String countryCode;
  final String? shopperReference;
  final String? storePaymentMethodMode;
  final String? recurringProcessingModel;
  final String? channel;

  SessionRequestNetworkModel({
    required this.merchantAccount,
    required this.amount,
    required this.returnUrl,
    required this.reference,
    required this.countryCode,
    this.shopperReference,
    this.storePaymentMethodMode,
    this.recurringProcessingModel,
    this.channel,
  });

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['merchantAccount'] = merchantAccount;
    data['amount'] = amount.toJson();
    data['returnUrl'] = returnUrl;
    data['reference'] = reference;
    data['countryCode'] = countryCode;
    data['shopperReference'] = shopperReference;
    data['storePaymentMethodMode'] = storePaymentMethodMode;
    data['recurringProcessingModel'] = recurringProcessingModel;
    data['channel'] = channel;
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
