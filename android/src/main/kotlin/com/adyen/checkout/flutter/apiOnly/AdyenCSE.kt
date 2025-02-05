package com.adyen.checkout.flutter.apiOnly

import com.adyen.checkout.cse.CardEncrypter
import com.adyen.checkout.flutter.generated.EncryptedCardDTO
import com.adyen.checkout.flutter.generated.UnencryptedCardDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.fromDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.mapToEncryptedCardDTO

internal object AdyenCSE {
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
}
