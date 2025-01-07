package com.adyen.checkout.flutter.cse

import CardNumberValidationResult as CardNumberValidationResultEnum
import EncryptedCardDTO
import UnencryptedCardDTO
import com.adyen.checkout.core.ui.validation.CardNumberValidationResult
import com.adyen.checkout.core.ui.validation.CardNumberValidator
import com.adyen.checkout.cse.CardEncrypter
import com.adyen.checkout.flutter.utils.ConfigurationMapper.fromDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEncryptedCardDTO
import java.lang.Exception

internal class AdyenCSE {
    fun encryptCard(
        unencryptedCardDTO: UnencryptedCardDTO,
        publicKey: String,
    ): Result<EncryptedCardDTO> {
        return try {
            val unencryptedCard = unencryptedCardDTO.fromDTO()
            val encryptedCard = CardEncrypter.encryptFields(unencryptedCard, publicKey)
            val encryptedCardDTO = encryptedCard.mapToEncryptedCardDTO()
            Result.success(encryptedCardDTO)
        } catch (exception: Exception) {
            Result.failure(exception)
        }
    }

    fun encryptBin(
        bin: String,
        publicKey: String,
    ): Result<String> {
        return try {
            val encryptedBin = CardEncrypter.encryptBin(bin, publicKey)
            Result.success(encryptedBin)
        } catch (exception: Exception) {
            Result.failure(exception)
        }
    }

    fun validateCardNumber(cardNumber: String, enableLuhnCheck: Boolean): CardNumberValidationResultEnum {
        val cardNumberValidationResult = CardNumberValidator.validateCardNumber(cardNumber, enableLuhnCheck)
        return when (cardNumberValidationResult) {
            is CardNumberValidationResult.Valid -> CardNumberValidationResultEnum.VALID
            is CardNumberValidationResult.Invalid.IllegalCharacters -> CardNumberValidationResultEnum.INVALIDILLEGALCHARACTERS
            is CardNumberValidationResult.Invalid.TooLong -> CardNumberValidationResultEnum.INVALIDTOOLONG
            is CardNumberValidationResult.Invalid.TooShort -> CardNumberValidationResultEnum.INVALIDTOOSHORT
            is CardNumberValidationResult.Invalid.LuhnCheck -> CardNumberValidationResultEnum.INVALIDLUHNCHECK
            else -> CardNumberValidationResultEnum.INVALIDOTHERREASON
        }
    }
}
