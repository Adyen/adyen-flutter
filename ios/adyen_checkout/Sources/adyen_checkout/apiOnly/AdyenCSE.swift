import Adyen
import AdyenEncryption
import Foundation

final class AdyenCSE {
    func encryptCard(
        unencryptedCardDTO: UnencryptedCardDTO,
        publicKey: String
    ) -> Result<EncryptedCardDTO, Error> {
        do {
            let encryptedCard = try CardEncryptor.encrypt(
                card: Card(
                    number: unencryptedCardDTO.cardNumber,
                    securityCode: unencryptedCardDTO.cvc,
                    expiryMonth: unencryptedCardDTO.expiryMonth,
                    expiryYear: unencryptedCardDTO.expiryYear
                ),
                with: publicKey
            )
            return .success(
                EncryptedCardDTO(
                    encryptedCardNumber: encryptedCard.number,
                    encryptedExpiryMonth: encryptedCard.expiryMonth,
                    encryptedExpiryYear: encryptedCard.expiryYear,
                    encryptedSecurityCode: encryptedCard.securityCode
                )
            )
        } catch {
            return .failure(error)
        }
    }

    func encryptBin(bin: String, publicKey: String) -> Result<String, Error> {
        do {
            return try .success(CardEncryptor.encrypt(bin: bin, with: publicKey))
        } catch {
            return .failure(error)
        }
    }
}
