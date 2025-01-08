package com.adyen.checkout.flutter.apiOnly

import CardNumberValidationResultDTO
import com.adyen.checkout.card.internal.data.model.Brand
import com.adyen.checkout.card.internal.util.CardExpiryDateValidation
import com.adyen.checkout.core.internal.ui.model.isEmptyDate
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

    internal fun validateExpiryDate(
        expiryDate: ExpiryDate,
        fieldPolicy: Brand.FieldPolicy?,
    ): CardExpiryDateValidation {
        val validationResult = CardExpiryDateValidator.validateExpiryDate(expiryDate)
        return when (validationResult) {
            is CardExpiryDateValidationResult.Valid -> CardExpiryDateValidation.VALID
            is CardExpiryDateValidationResult.Invalid.TooFarInTheFuture -> CardExpiryDateValidation.INVALID_TOO_FAR_IN_THE_FUTURE
            is CardExpiryDateValidationResult.Invalid.TooOld -> CardExpiryDateValidation.INVALID_TOO_OLD
            is CardExpiryDateValidationResult.Invalid.NonParseableDate -> {
                if (expiryDate.isEmptyDate() && fieldPolicy?.isRequired() == false) {
                    CardExpiryDateValidation.VALID_NOT_REQUIRED
                } else {
                    CardExpiryDateValidation.INVALID_OTHER_REASON
                }
            }

            else -> CardExpiryDateValidation.INVALID_OTHER_REASON
        }
    }
}
