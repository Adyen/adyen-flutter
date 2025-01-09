import 'dart:async';

import 'package:adyen_checkout/adyen_checkout.dart';
import 'package:adyen_checkout/src/adyen_checkout_interface.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_advanced.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_api.dart';
import 'package:adyen_checkout/src/common/adyen_checkout_session.dart';
import 'package:adyen_checkout/src/components/action_handling/action_component.dart';
import 'package:adyen_checkout/src/drop_in/drop_in.dart';
import 'package:adyen_checkout/src/drop_in/drop_in_flutter_api.dart';
import 'package:adyen_checkout/src/drop_in/drop_in_platform_api.dart';
import 'package:adyen_checkout/src/generated/platform_api.g.dart';
import 'package:adyen_checkout/src/logging/adyen_logger.dart';
import 'package:adyen_checkout/src/util/dto_mapper.dart';
import 'package:adyen_checkout/src/util/sdk_version_number_provider.dart';
import 'package:flutter/foundation.dart';

class AdyenCheckout implements AdyenCheckoutInterface {
  static AdyenCheckout? _instance;
  static AdyenCheckoutSession? _session;
  static AdyenCheckoutAdvanced? _advanced;
  static final AdyenCheckoutApi _adyenCheckoutApi = AdyenCheckoutApi();
  static final DropIn _dropIn = DropIn(
    SdkVersionNumberProvider.instance,
    DropInFlutterApi(),
    DropInPlatformApi(),
  );

  static AdyenCheckout get instance => _instance ??= AdyenCheckout._init();

  static AdyenCheckoutAdvanced get advanced =>
      _advanced ??= AdyenCheckoutAdvanced(_adyenCheckoutApi, _dropIn);

  static AdyenCheckoutSession get session =>
      _session ??= AdyenCheckoutSession(_adyenCheckoutApi, _dropIn);

  AdyenCheckout._init();

  @override
  Future<String> getReturnUrl() async => _adyenCheckoutApi.getReturnUrl();

  @override
  void enableConsoleLogging({required bool enabled}) {
    if (kDebugMode) {
      AdyenLogger.instance.enableConsoleLogging(loggingEnabled: enabled);
      _adyenCheckoutApi.enableConsoleLogging(enabled);
    }
  }

  @override
  Future<EncryptedCard> encryptCard(
    UnencryptedCard unencryptedCard,
    String publicKey,
  ) async {
    final unencryptedCardDTO = unencryptedCard.toDTO();
    final encryptedCardDTO =
        await _adyenCheckoutApi.encryptCard(unencryptedCardDTO, publicKey);
    return encryptedCardDTO.fromDTO();
  }

  @override
  Future<String> encryptBin(
    String bin,
    String publicKey,
  ) =>
      _adyenCheckoutApi.encryptBin(bin, publicKey);

  @override
  Future<ActionResult> handleAction(
    ActionComponentConfiguration actionComponentConfiguration,
    Map<String, dynamic> action,
  ) =>
      ActionComponent().handleAction(actionComponentConfiguration, action);

  Future<CardNumberValidationResult> validateCardNumber({
    required String cardNumber,
    bool enableLuhnCheck = true,
  }) async {
    final CardNumberValidationResultDTO cardNumberValidation =
        await _adyenCheckoutApi.validateCardNumber(
      cardNumber,
      enableLuhnCheck,
    );

    return switch (cardNumberValidation) {
      CardNumberValidationResultDTO.valid => ValidCardNumber(),
      CardNumberValidationResultDTO.invalidLuhnCheck ||
      CardNumberValidationResultDTO.invalidIllegalCharacters ||
      CardNumberValidationResultDTO.invalidTooShort ||
      CardNumberValidationResultDTO.invalidTooLong ||
      CardNumberValidationResultDTO.invalidOtherReason =>
        InvalidCardNumberOtherReason()
    };
  }

  Future<CardExpiryDateValidationResult> validateCardExpireDate({
    required String expiryMonth,
    required String expiryYear,
  }) async {
    final CardExpiryDateValidationResultDTO cardExpiryDateValidationResultDTO =
        await _adyenCheckoutApi.validateCardExpiryDate(
      expiryMonth,
      expiryYear,
    );

    return switch (cardExpiryDateValidationResultDTO) {
      CardExpiryDateValidationResultDTO.valid => ValidCardExpiryDate(),
      CardExpiryDateValidationResultDTO.invalidTooFarInTheFuture ||
      CardExpiryDateValidationResultDTO.invalidTooOld ||
      CardExpiryDateValidationResultDTO.nonParseableDate ||
      CardExpiryDateValidationResultDTO.invalidOtherReason =>
        InvalidCardExpiryDateOtherReason()
    };
  }

  Future<CardSecurityCodeValidationResult> validateCardSecurityCode({
    required String securityCode,
    String? cardBrandTxVariant,
  }) async {
    final CardSecurityCodeValidationResultDTO
        cardSecurityCodeValidationResultDTO =
        await _adyenCheckoutApi.validateCardSecurityCode(
      securityCode,
      cardBrandTxVariant,
    );

    return switch (cardSecurityCodeValidationResultDTO) {
      CardSecurityCodeValidationResultDTO.valid => ValidCardSecurityCode(),
      CardSecurityCodeValidationResultDTO.invalid => InvalidCardSecurityCode()
    };
  }
}
