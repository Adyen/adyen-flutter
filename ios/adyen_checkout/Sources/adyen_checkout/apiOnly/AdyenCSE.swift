import AdyenEncryption

class AdyenCSE {
    func encryptCard(unencryptedCardDTO: UnencryptedCardDTO, publicKey: String) -> Result<EncryptedCardDTO, any Error> {
        do {
            let unencryptedCard = unencryptedCardDTO.mapToUnencryptedCard()
            let encryptedCard = try CardEncryptor.encrypt(card: unencryptedCard, with: publicKey)
            let encryptedCardDTO = encryptedCard.mapToEncryptedCardDTO()
            return Result.success(encryptedCardDTO)
        } catch {
            return Result.failure(error)
        }
    }
    
    func encryptBin(bin: String, publicKey: String) -> Result<String, any Error> {
        do {
            let encryptedBin = try CardEncryptor.encrypt(bin: bin, with: publicKey)
            return Result.success(encryptedBin)
        } catch {
            return Result.failure(error)
        }
    }
}
