import Adyen

class AdyenCSE {
    func encryptCard(unencryptedCardDTO: UnencryptedCardDTO, publicKey: String, completion: @escaping (Result<EncryptedCardDTO, any Error>) -> Void) {
        do {
            let unencryptedCard = unencryptedCardDTO.mapToUnencryptedCard()
            let encryptedCard = try CardEncryptor.encrypt(card: unencryptedCard, with: publicKey)
            let encryptedCardDTO = encryptedCard.mapToEncryptedCardDTO()
            completion(Result.success(encryptedCardDTO))
        } catch {
            completion(Result.failure(error))
        }
    }
    
    func encryptBin(bin: String, publicKey: String, completion: @escaping (Result<String, any Error>) -> Void) {
        do {
            let encryptedBin = try CardEncryptor.encrypt(bin: bin, with: publicKey)
            completion(Result.success(encryptedBin))
        } catch {
            completion(Result.failure(error))
        }
    }
}
