package com.adyen.checkout.flutter.apiOnly

import com.adyen.checkout.core.common.CardBrand
import com.adyen.checkout.core.common.helper.CardExpiryDateValidationResult
import com.adyen.checkout.core.common.helper.CardExpiryDateValidator
import com.adyen.checkout.core.common.helper.CardNumberValidationResult
import com.adyen.checkout.core.common.helper.CardNumberValidator
import com.adyen.checkout.core.common.helper.CardSecurityCodeValidationResult
import com.adyen.checkout.core.common.helper.CardSecurityCodeValidator

internal object CardValidation {
    fun validateCardNumber(cardNumber: String, enableLuhnCheck: Boolean): Boolean =
        CardNumberValidator.validateCardNumber(cardNumber, enableLuhnCheck) is CardNumberValidationResult.Valid

    fun validateCardExpiryDate(expiryMonth: String, expiryYear: String): Boolean {
        if (!expiryMonth.matches(Regex("\\d{2}")) || !expiryYear.matches(Regex("\\d{2}"))) {
            return false
        }
        return CardExpiryDateValidator.validateExpiryDate(expiryMonth, expiryYear) is CardExpiryDateValidationResult.Valid
    }

    fun validateCardSecurityCode(securityCode: String, cardBrand: String?): Boolean {
        val result = CardSecurityCodeValidator.validateSecurityCode(
            securityCode = securityCode,
            cardBrand = cardBrand?.let(::CardBrand),
        )
        return result is CardSecurityCodeValidationResult.Valid
    }
}
