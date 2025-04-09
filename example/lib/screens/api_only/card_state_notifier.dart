import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/adyen_cse_repository.dart';
import 'package:adyen_checkout_example/screens/api_only/card_state.dart';
import 'package:flutter/widgets.dart';

class CardStateNotifier extends ValueNotifier<CardState> {
  CardStateNotifier(this.repository) : super(CardState());

  final AdyenCseRepository repository;
  final formKey = GlobalKey<FormState>();
  final cardDetailsTriggerThreshold = 6;
  Timer? _throttleTimer;

  Future<void> updateCardNumber(String cardNumber) async {
    final String cardNumberTrimmed = cardNumber.trim();
    _fetchCardDetails(cardNumberTrimmed);
    final CardNumberValidationResult cardNumberValidationResult =
        await _validateCardNumberInput(cardNumberTrimmed);
    triggerFromValidationThrottled();
    value = value.copyWith(
      cardNumberValidationResult: cardNumberValidationResult,
      cardNumber: cardNumberTrimmed,
    );
  }

  Future<void> updateExpiryDate(String expiryDate) async {
    final index = expiryDate.indexOf('/');
    if (index == -1) {
      return;
    }

    final String expiryMonth = expiryDate.substring(0, index);
    final String expiryYear = "20${expiryDate.substring(index + 1)}";
    final CardExpiryDateValidationResult cardExpiryDateValidationResult =
        await _validateExpiryDate(expiryMonth, expiryYear);
    triggerFromValidationThrottled();
    value = value.copyWith(
      expiryMoth: expiryMonth,
      expiryYear: expiryYear,
      cardExpiryDateValidationResult: cardExpiryDateValidationResult,
    );
  }

  Future<void> updateSecurityCode(String securityCode) async {
    final CardSecurityCodeValidationResult cardSecurityCodeValidationResult =
        await _validateSecurityCode(
      securityCode,
      value.relatedCardBrands?.firstOrNull ?? "",
    );
    triggerFromValidationThrottled();
    value = value.copyWith(
      securityCode: securityCode,
      cardSecurityCodeValidationResult: cardSecurityCodeValidationResult,
    );
  }

  void reset() {
    value = CardState();
  }

  Future<CardNumberValidationResult> _validateCardNumberInput(
      String cardNumber) async {
    final CardNumberValidationResult cardNumberValidationResult =
        await AdyenCheckout.instance.validateCardNumber(
      cardNumber: cardNumber,
      enableLuhnCheck: true,
    );

    switch (cardNumberValidationResult) {
      case ValidCardNumber():
        debugPrint("Card number is valid.");
      case InvalidCardNumber it:
        switch (it) {
          case InvalidCardNumberOtherReason _:
            debugPrint("Card number is invalid due to other reason.");
        }
    }

    return cardNumberValidationResult;
  }

  Future<CardExpiryDateValidationResult> _validateExpiryDate(
    String expiryMonth,
    String expiryYear,
  ) async {
    final CardExpiryDateValidationResult cardExpiryDateValidationResult =
        await AdyenCheckout.instance.validateCardExpiryDate(
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
    );

    switch (cardExpiryDateValidationResult) {
      case ValidCardExpiryDate():
        debugPrint("Card expire date is valid.");
      case InvalidCardExpiryDate it:
        switch (it) {
          case InvalidCardExpiryDateOtherReason _:
            debugPrint("Card expire date is invalid due to other reason.");
        }
    }
    return cardExpiryDateValidationResult;
  }

  Future<CardSecurityCodeValidationResult> _validateSecurityCode(
    String securityCode,
    String brand,
  ) async {
    final CardSecurityCodeValidationResult cardSecurityCodeValidationResult =
        await AdyenCheckout.instance.validateCardSecurityCode(
      securityCode: securityCode,
      cardBrand: brand,
    );
    switch (cardSecurityCodeValidationResult) {
      case ValidCardSecurityCode():
        debugPrint("Card security code is valid.");
      case InvalidCardSecurityCode():
        debugPrint("Card security code is invalid.");
    }
    return cardSecurityCodeValidationResult;
  }

  void triggerFromValidationThrottled() {
    _throttleTimer?.cancel();
    _throttleTimer =
        Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      formKey.currentState?.validate();
      _throttleTimer?.cancel();
    });
  }

  Future<ResultCode?> pay() async {
    final isInputValid = formKey.currentState?.validate();
    if (isInputValid == true) {
      value = value.copyWith(loading: true);
      final UnencryptedCard unencryptedCard = UnencryptedCard(
        cardNumber: value.cardNumber,
        expiryMonth: value.expiryMoth,
        expiryYear: value.expiryYear,
        cvc: value.securityCode,
      );
      final EncryptedCard encryptedCard = await AdyenCheckout.instance
          .encryptCard(unencryptedCard, Config.publicKey);
      final Map<String, dynamic> paymentsResponse =
          await repository.payments(encryptedCard);
      if (paymentsResponse.containsKey("action")) {
        final actionResult = await _handleAction(paymentsResponse);
        switch (actionResult) {
          case ActionSuccess it:
            final paymentsDetailsResponse =
                await repository.paymentsDetails(it.data);
            return _mapToResultCode(paymentsDetailsResponse);
          case ActionError it:
            debugPrint("Action error: ${it.errorMessage}");
        }
      } else {
        return _mapToResultCode(paymentsResponse);
      }
    }
    return null;
  }

  Future<void> _fetchCardDetails(String cardNumber) async {
    if (cardNumber.length < cardDetailsTriggerThreshold) {
      return;
    }

    final unencryptedCard = UnencryptedCard(cardNumber: cardNumber);
    final encryptedCard = await AdyenCheckout.instance.encryptCard(
      unencryptedCard,
      Config.publicKey,
    );
    final encryptedCardNumber = encryptedCard.encryptedCardNumber;
    if (encryptedCardNumber != null) {
      final cardDataResponse =
          await repository.cardDetails(encryptedCardNumber);
      final relatedCardBrands = _mapToRelatedCardBrands(cardDataResponse);
      value = value.copyWith(relatedCardBrands: relatedCardBrands);
    }
  }

  Future<ActionResult> _handleAction(
      Map<String, dynamic> paymentsResponse) async {
    final ActionComponentConfiguration actionComponentConfiguration =
        ActionComponentConfiguration(
      environment: Config.environment,
      clientKey: Config.clientKey,
      shopperLocale: Config.shopperLocale,
    );

    final ActionResult actionResult = await AdyenCheckout.instance.handleAction(
      actionComponentConfiguration,
      paymentsResponse["action"],
    );

    return actionResult;
  }

  ResultCode _mapToResultCode(Map<String, dynamic> paymentsResponse) {
    final String? resultCode = paymentsResponse["resultCode"];
    return ResultCode.values.firstWhere(
      (element) => element.name.toLowerCase() == resultCode?.toLowerCase(),
      orElse: () => ResultCode.unknown,
    );
  }

  List<String>? _mapToRelatedCardBrands(Map<String, dynamic> jsonResponse) {
    final List<dynamic>? brands = jsonResponse['brands'];
    if (brands == null || brands.isEmpty) {
      return [];
    }

    return brands
        .where((brand) => brand['supported'] == true)
        .map<String>((brand) => brand['type'].toString())
        .toSet()
        .toList();
  }
}
