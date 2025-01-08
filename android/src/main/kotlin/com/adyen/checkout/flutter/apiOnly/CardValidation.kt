package com.adyen.checkout.flutter.apiOnly

import CardExpiryDateValidationResultDTO
import CardNumberValidationResultDTO
import com.adyen.checkout.core.ui.model.ExpiryDate
import com.adyen.checkout.core.ui.validation.CardExpiryDateValidationResult
import com.adyen.checkout.core.ui.validation.CardExpiryDateValidator
import com.adyen.checkout.core.ui.validation.CardNumberValidationResult
import com.adyen.checkout.core.ui.validation.CardNumberValidator

object CardValidation {
    internal fun validateCardNumber(cardNumber: String, enableLuhnCheck: Boolean): CardNumberValidationResultDTO {
        val cardNumberValidationResult = CardNumberValidator.validateCardNumber(cardNumber, enableLuhnCheck)
        return when (cardNumberValidationResult) {
            is CardNumberValidationResult.Valid -> CardNumberValidationResultDTO.VALID
            is CardNumberValidationResult.Invalid.IllegalCharacters -> CardNumberValidationResultDTO.INVALIDILLEGALCHARACTERS
            is CardNumberValidationResult.Invalid.TooLong -> CardNumberValidationResultDTO.INVALIDTOOLONG
            is CardNumberValidationResult.Invalid.TooShort -> CardNumberValidationResultDTO.INVALIDTOOSHORT
            is CardNumberValidationResult.Invalid.LuhnCheck -> CardNumberValidationResultDTO.INVALIDLUHNCHECK
            else -> CardNumberValidationResultDTO.INVALIDOTHERREASON
        }
    }

    internal fun validateCardExpiryDate(expiryMonth: String, expiryYear: String): CardExpiryDateValidationResultDTO {
        val expireMonth = expiryMonth.toIntOrNull() ?: return CardExpiryDateValidationResultDTO.NONPARSEABLEDATE
        val expireYear = expiryYear.toIntOrNull() ?: return CardExpiryDateValidationResultDTO.NONPARSEABLEDATE
        val cardExpiryDate = ExpiryDate(expireMonth, expireYear)
        val validationResult = CardExpiryDateValidator.validateExpiryDate(cardExpiryDate)
        return when (validationResult) {
            is CardExpiryDateValidationResult.Valid -> CardExpiryDateValidationResultDTO.VALID
            is CardExpiryDateValidationResult.Invalid.TooFarInTheFuture -> CardExpiryDateValidationResultDTO.INVALIDTOOFARINTHEFUTURE
            is CardExpiryDateValidationResult.Invalid.TooOld -> CardExpiryDateValidationResultDTO.INVALIDTOOOLD
            is CardExpiryDateValidationResult.Invalid.NonParseableDate -> CardExpiryDateValidationResultDTO.NONPARSEABLEDATE
            else -> CardExpiryDateValidationResultDTO.INVALIDOTHERREASON
        }
    }
}
