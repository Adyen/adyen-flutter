package com.adyen.checkout.flutter.cse

import EncryptedCardDTO
import UnencryptedCardDTO
import com.adyen.checkout.cse.CardEncrypter
import com.adyen.checkout.flutter.utils.ConfigurationMapper.fromDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEncryptedCardDTO
import java.lang.Exception

internal class AdyenCSE {
    fun encryptCard(
        unencryptedCardDTO: UnencryptedCardDTO,
        publicKey: String,
        callback: (Result<EncryptedCardDTO>) -> Unit
    ) {
        try {
            val unencryptedCard = unencryptedCardDTO.fromDTO()
            val encryptedCard = CardEncrypter.encryptFields(unencryptedCard, publicKey)
            val encryptedCardDTO = encryptedCard.mapToEncryptedCardDTO()
            callback(Result.success(encryptedCardDTO))
        } catch (exception: Exception) {
            callback(Result.failure(exception))
        }
    }

    fun encryptBin(
        bin: String,
        publicKey: String,
        callback: (Result<String>) -> Unit
    ) {
        try {
            val encryptedBin = CardEncrypter.encryptBin(bin, publicKey)
            callback(Result.success(encryptedBin))
        } catch (exception: Exception) {
            callback(Result.failure(exception))
        }
    }
}
