package com.adyen.checkout.flutter.cse

import EncryptedCardDTO
import UnencryptedCardDTO
import com.adyen.checkout.cse.CardEncrypter
import com.adyen.checkout.cse.UnencryptedCard
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEncryptedCardDTO
import java.lang.Exception

class AdyenCSE {

    fun encryptCard(
        unencryptedCardDTO: UnencryptedCardDTO,
        publicKey: String,
        callback: (Result<EncryptedCardDTO>) -> Unit
    ) {
        try {
            val unencryptedCard = buildUnencryptedCard(unencryptedCardDTO)
            val encryptedCard = CardEncrypter.encryptFields(unencryptedCard, publicKey)
            val encryptedCardDTO = encryptedCard.mapToEncryptedCardDTO()
            callback(Result.success(encryptedCardDTO))
        } catch (exception: Exception) {
            callback(Result.failure(exception))
        }
    }

    fun encrypt(
        unencryptedCardDTO: UnencryptedCardDTO,
        publicKey: String,
        callback: (Result<String>) -> Unit
    ) {
        try {
            val unencryptedCard = buildUnencryptedCard(unencryptedCardDTO)
            val encryptedCardBlock = CardEncrypter.encrypt(unencryptedCard, publicKey)
            callback(Result.success(encryptedCardBlock))
        } catch (exception: Exception) {
            callback(Result.failure(exception))
        }
    }

    private fun buildUnencryptedCard(unencryptedCardDTO: UnencryptedCardDTO): UnencryptedCard {
        val unencryptedCardBuilder = UnencryptedCard.Builder()
        unencryptedCardDTO.cardNumber?.let { unencryptedCardBuilder.setNumber(it) }
        if (unencryptedCardDTO.expiryMonth != null && unencryptedCardDTO.expiryYear != null) {
            unencryptedCardBuilder.setExpiryDate(unencryptedCardDTO.expiryMonth, unencryptedCardDTO.expiryYear)
        }
        unencryptedCardDTO.cvc?.let { unencryptedCardBuilder.setCvc(it) }
        unencryptedCardDTO.cardHolderName?.let { unencryptedCardBuilder.setHolderName(it) }
        return unencryptedCardBuilder.build()
    }
}
