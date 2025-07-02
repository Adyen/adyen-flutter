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
        Timer.periodic(const Duration(milliseconds: 750), (timer) async {
      formKey.currentState?.validate();
      _throttleTimer?.cancel();
    });
  }

  Future<ResultCode?> pay() async {
    final bool isInputValid = await _validateInput();
    if (isInputValid == false) {
      return null;
    }

    value = value.copyWith(loading: true);
    final EncryptedCard encryptedCard = await _createEncryptedCard();
    final String threeDS2SdkVersion =
        await AdyenCheckout.instance.getThreeDS2SdkVersion();
    final Map<String, dynamic> paymentsResponse = await repository.payments(
      encryptedCard: encryptedCard,
      threeDS2SdkVersion: threeDS2SdkVersion,
    );
    if (paymentsResponse.containsKey("action")) {
      final ActionResult actionResult = await _handleAction(paymentsResponse);
      return _mapActionResultToResultCode(actionResult);
    }

    return _mapToResultCode(paymentsResponse);
  }

  Future<EncryptedCard> _createEncryptedCard() async {
    final UnencryptedCard unencryptedCard = UnencryptedCard(
      cardNumber: value.cardNumber,
      expiryMonth: value.expiryMoth,
      expiryYear: value.expiryYear,
      cvc: value.securityCode,
    );
    return await AdyenCheckout.instance.encryptCard(
      unencryptedCard,
      Config.publicKey,
    );
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

  Future<ResultCode> _mapActionResultToResultCode(
      ActionResult actionResult) async {
    switch (actionResult) {
      case ActionSuccess it:
        final paymentsDetailsResponse =
            await repository.paymentsDetails(it.data);
        return _mapToResultCode(paymentsDetailsResponse);
      case ActionError it:
        debugPrint("Action error: ${it.errorMessage}");
        return ResultCode.error;
    }
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

  Future<bool> _validateInput() async {
    final cardNumberValidationResult = await _validateCardNumberInput(
      value.cardNumber ?? "",
    );
    final cardExpiryDateValidationResult = await _validateExpiryDate(
      value.expiryMoth ?? "",
      value.expiryYear ?? "",
    );
    final cardSecurityCodeValidationResult = await _validateSecurityCode(
      value.securityCode ?? "",
      value.relatedCardBrands?.firstOrNull ?? "",
    );

    value = value.copyWith(
      cardNumberValidationResult: cardNumberValidationResult,
      cardExpiryDateValidationResult: cardExpiryDateValidationResult,
      cardSecurityCodeValidationResult: cardSecurityCodeValidationResult,
    );
    return value.isInputValid;
  }
}
