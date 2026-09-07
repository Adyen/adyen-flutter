package com.adyen.checkout.flutter.apiOnly

import com.adyen.checkout.cse.CardEncrypter
import com.adyen.checkout.flutter.generated.EncryptedCardDTO
import com.adyen.checkout.flutter.generated.UnencryptedCardDTO
import com.adyen.checkout.flutter.utils.ConfigurationMapper.toNativeUnencryptedCard

internal object AdyenCSE {
    fun encryptCard(
        card: UnencryptedCardDTO,
        publicKey: String,
    ): EncryptedCardDTO {
        val encryptedCard = CardEncrypter.encryptFields(card.toNativeUnencryptedCard(), publicKey)
        return EncryptedCardDTO(
            encryptedCardNumber = encryptedCard.encryptedCardNumber,
            encryptedExpiryMonth = encryptedCard.encryptedExpiryMonth,
            encryptedExpiryYear = encryptedCard.encryptedExpiryYear,
            encryptedSecurityCode = encryptedCard.encryptedSecurityCode,
        )
    }

    fun encryptBin(bin: String, publicKey: String): String =
        CardEncrypter.encryptBin(bin, publicKey)
}
