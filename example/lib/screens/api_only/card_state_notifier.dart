import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout_example/config.dart';
import 'package:adyen_checkout_example/repositories/advanced_checkout_repository.dart';
import 'package:adyen_checkout_example/screens/api_only/card_state.dart';
import 'package:flutter/material.dart';

class CardStateNotifier extends ValueNotifier<CardState> {
  final AdvancedCheckoutRepository repository;
  final formKey = GlobalKey<FormState>();
  final cardDetailsTriggerThreshold = 6;
  Timer? _throttleTimer;

  CardStateNotifier({required this.repository}) : super(CardState());

  Future<void> updateCardNumber(String cardNumber) async {
    final trimmed = cardNumber.replaceAll(' ', '').trim();
    _fetchCardDetails(trimmed);
    if (trimmed.length < 8) {
      value = value.copyWith(
        cardNumber: trimmed,
        isCardNumberValid: null,
      );
      return;
    }
    final isValid = await Checkout.instance.validateCardNumber(
      cardNumber: trimmed,
      enableLuhnCheck: true,
    );
    triggerFormValidationThrottled();
    value = value.copyWith(
      cardNumber: trimmed,
      isCardNumberValid: isValid,
    );
  }

  Future<void> updateExpiryDate(String expiryDate) async {
    final index = expiryDate.indexOf('/');
    if (index == -1) {
      value = value.copyWith(
        expiryMonth: null,
        expiryYear: null,
        isExpiryDateValid: null,
      );
      return;
    }

    final expiryMonth = expiryDate.substring(0, index);
    var rawYear = expiryDate.substring(index + 1);
    if (rawYear.length == 4 && rawYear.startsWith('20')) {
      rawYear = rawYear.substring(2);
    }

    if (rawYear.length < 2) {
      value = value.copyWith(
        expiryMonth: expiryMonth,
        expiryYear: null,
        isExpiryDateValid: null,
      );
      return;
    }

    final isValid = await Checkout.instance.validateCardExpiryDate(
      expiryMonth: expiryMonth,
      expiryYear: rawYear,
    );
    triggerFormValidationThrottled();
    value = value.copyWith(
      expiryMonth: expiryMonth,
      expiryYear: rawYear,
      isExpiryDateValid: isValid,
    );
  }

  Future<void> updateSecurityCode(String securityCode) async {
    if (securityCode.length < 3) {
      value = value.copyWith(
        securityCode: securityCode,
        isSecurityCodeValid: null,
      );
      return;
    }
    final isValid = await Checkout.instance.validateCardSecurityCode(
      securityCode: securityCode,
      cardBrand: value.relatedCardBrands?.firstOrNull,
    );
    triggerFormValidationThrottled();
    value = value.copyWith(
      securityCode: securityCode,
      isSecurityCodeValid: isValid,
    );
  }

  void reset() {
    value = CardState();
  }

  void triggerFormValidationThrottled() {
    _throttleTimer?.cancel();
    _throttleTimer = Timer(const Duration(milliseconds: 750), () {
      formKey.currentState?.validate();
    });
  }

  Future<String?> pay() async {
    final isInputValid = await _validateInput();
    if (!isInputValid) return null;

    value = value.copyWith(loading: true);
    try {
      final encryptedCard = await _createEncryptedCard();
      final threeDS2SdkVersion = await Checkout.instance.getThreeDS2SdkVersion();
      final paymentsResponse = await repository.service.postPayments({
        'merchantAccount': Config.merchantAccount,
        'shopperReference': Config.shopperReference,
        'reference':
            'flutter-custom-card_${DateTime.now().millisecondsSinceEpoch}',
        'returnUrl': repository.determineReturnUrl(),
        'amount': Config.amount.toJson(),
        'countryCode': Config.countryCode,
        'channel': repository.channel,
        'recurringProcessingModel': 'CardOnFile',
        'shopperInteraction': 'Ecommerce',
        'paymentMethod': {
          'type': 'scheme',
          'encryptedCardNumber': encryptedCard.encryptedCardNumber,
          'encryptedExpiryMonth': encryptedCard.encryptedExpiryMonth,
          'encryptedExpiryYear': encryptedCard.encryptedExpiryYear,
          'encryptedSecurityCode': encryptedCard.encryptedSecurityCode,
          'threeDS2SdkVersion': threeDS2SdkVersion,
        },
        'authenticationData': {
          'threeDSRequestData': {
            'nativeThreeDS': 'preferred',
          },
        },
      });

      final action = paymentsResponse['action'];
      if (action is Map) {
        final result = await repository.handleAction(
          actionJson: Map<String, dynamic>.from(action),
          onAdditionalDetails: repository.onAdditionalDetails,
        );
        return result.resultCode;
      }

      return paymentsResponse['resultCode'] as String? ?? 'Authorised';
    } finally {
      value = value.copyWith(loading: false);
    }
  }

  Future<EncryptedCard> _createEncryptedCard() async {
    final year = value.expiryYear;
    final fullYear = year != null && year.length == 2 ? '20$year' : year;
    final unencryptedCard = UnencryptedCard(
      cardNumber: value.cardNumber,
      expiryMonth: value.expiryMonth,
      expiryYear: fullYear,
      cvc: value.securityCode,
    );
    return Checkout.instance.encryptCard(
      card: unencryptedCard,
      publicKey: Config.publicKey,
    );
  }

  Future<void> _fetchCardDetails(String cardNumber) async {
    if (cardNumber.length < cardDetailsTriggerThreshold) return;

    try {
      final encryptedCard = await Checkout.instance.encryptCard(
        card: UnencryptedCard(cardNumber: cardNumber),
        publicKey: Config.publicKey,
      );
      final encryptedCardNumber = encryptedCard.encryptedCardNumber;
      if (encryptedCardNumber != null) {
        final cardDataResponse = await repository.service.postCardDetails({
          'merchantAccount': Config.merchantAccount,
          'encryptedCardNumber': encryptedCardNumber,
        });
        final relatedCardBrands = _mapToRelatedCardBrands(cardDataResponse);
        value = value.copyWith(relatedCardBrands: relatedCardBrands);
      }
    } catch (_) {
      // Gracefully ignore if card details lookup is not supported by endpoint
    }
  }

  List<String>? _mapToRelatedCardBrands(Map<String, dynamic> jsonResponse) {
    final brands = jsonResponse['brands'] as List<dynamic>?;
    if (brands == null || brands.isEmpty) return [];

    return brands
        .where((brand) => brand['supported'] == true)
        .map<String>((brand) => brand['type'].toString())
        .toSet()
        .toList();
  }

  Future<bool> _validateInput() async {
    final isCardNumberValid = await Checkout.instance.validateCardNumber(
      cardNumber: value.cardNumber ?? '',
      enableLuhnCheck: true,
    );
    final expiryYear = value.expiryYear ?? '';
    final normalizedExpiryYear =
        expiryYear.length == 4 && expiryYear.startsWith('20')
            ? expiryYear.substring(2)
            : expiryYear;
    final isExpiryDateValid = await Checkout.instance.validateCardExpiryDate(
      expiryMonth: value.expiryMonth ?? '',
      expiryYear: normalizedExpiryYear,
    );
    final isSecurityCodeValid = await Checkout.instance.validateCardSecurityCode(
      securityCode: value.securityCode ?? '',
      cardBrand: value.relatedCardBrands?.firstOrNull,
    );

    value = value.copyWith(
      isCardNumberValid: isCardNumberValid,
      isExpiryDateValid: isExpiryDateValid,
      isSecurityCodeValid: isSecurityCodeValid,
    );
    formKey.currentState?.validate();
    return value.isInputValid;
  }
}
