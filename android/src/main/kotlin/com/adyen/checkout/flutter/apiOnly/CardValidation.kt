package com.adyen.checkout.flutter.apiOnly

import com.adyen.checkout.core.old.CardBrand
import com.adyen.checkout.core.old.ui.model.ExpiryDate
import com.adyen.checkout.core.old.ui.validation.CardExpiryDateValidationResult
import com.adyen.checkout.core.old.ui.validation.CardExpiryDateValidator
import com.adyen.checkout.core.old.ui.validation.CardNumberValidationResult
import com.adyen.checkout.core.old.ui.validation.CardNumberValidator
import com.adyen.checkout.core.old.ui.validation.CardSecurityCodeValidationResult
import com.adyen.checkout.core.old.ui.validation.CardSecurityCodeValidator
import com.adyen.checkout.flutter.generated.CardExpiryDateValidationResultDTO
import com.adyen.checkout.flutter.generated.CardNumberValidationResultDTO
import com.adyen.checkout.flutter.generated.CardSecurityCodeValidationResultDTO

internal object CardValidation {
    fun validateCardNumber(
        cardNumber: String,
        enableLuhnCheck: Boolean
    ): CardNumberValidationResultDTO {
        val validationResult = CardNumberValidator.validateCardNumber(cardNumber, enableLuhnCheck)
        return when (validationResult) {
            is CardNumberValidationResult.Valid -> CardNumberValidationResultDTO.VALID
            is CardNumberValidationResult.Invalid.IllegalCharacters ->
                CardNumberValidationResultDTO.INVALID_ILLEGAL_CHARACTERS

            is CardNumberValidationResult.Invalid.TooLong -> CardNumberValidationResultDTO.INVALID_TOO_LONG
            is CardNumberValidationResult.Invalid.TooShort -> CardNumberValidationResultDTO.INVALID_TOO_SHORT
            is CardNumberValidationResult.Invalid.LuhnCheck -> CardNumberValidationResultDTO.INVALID_LUHN_CHECK
            else -> CardNumberValidationResultDTO.INVALID_OTHER_REASON
        }
    }

    fun validateCardExpiryDate(
        expiryMonth: String,
        expiryYear: String
    ): CardExpiryDateValidationResultDTO {
        val expireMonth = expiryMonth.toIntOrNull() ?: return CardExpiryDateValidationResultDTO.NON_PARSEABLE_DATE
        val expireYear = expiryYear.toIntOrNull() ?: return CardExpiryDateValidationResultDTO.NON_PARSEABLE_DATE
        val expiryDate = ExpiryDate(expireMonth, expireYear)
        val validationResult = CardExpiryDateValidator.validateExpiryDate(expiryDate)
        return when (validationResult) {
            is CardExpiryDateValidationResult.Valid -> CardExpiryDateValidationResultDTO.VALID
            is CardExpiryDateValidationResult.Invalid.TooFarInTheFuture ->
                CardExpiryDateValidationResultDTO.INVALID_TOO_FAR_IN_THE_FUTURE
            is CardExpiryDateValidationResult.Invalid.TooOld -> CardExpiryDateValidationResultDTO.INVALID_TOO_OLD
            is CardExpiryDateValidationResult.Invalid.NonParseableDate ->
                CardExpiryDateValidationResultDTO.NON_PARSEABLE_DATE
            else -> CardExpiryDateValidationResultDTO.INVALID_OTHER_REASON
        }
    }

    fun validateCardSecurityCode(
        securityCode: String,
        cardBrand: String?
    ): CardSecurityCodeValidationResultDTO {
        val cardType = cardBrand?.let { CardBrand(it) }
        val validationResult = CardSecurityCodeValidator.validateSecurityCode(securityCode, cardType)
        return when (validationResult) {
            is CardSecurityCodeValidationResult.Valid -> CardSecurityCodeValidationResultDTO.VALID
            is CardSecurityCodeValidationResult.Invalid -> CardSecurityCodeValidationResultDTO.INVALID
        }
    }
}
