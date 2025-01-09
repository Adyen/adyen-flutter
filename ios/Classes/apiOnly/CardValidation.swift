import Adyen

class CardValidation {
    func validateCardNumber(cardNumber: String, enableLuhnCheck: Bool) -> Bool {
        return CardNumberValidator(isLuhnCheckEnabled: enableLuhnCheck, isEnteredBrandSupported: true).isValid(cardNumber)
    }
    
    func validateCardExpiryDate(expiryMonth: String, expiryYear: String) -> Bool {
        let lastTwoYearChars = String(expiryYear.suffix(2))
        return CardExpiryDateValidator().isValid("\(expiryMonth)\(lastTwoYearChars)")
    }
    
    func validateCardSecurityCode(securityCode: String, cardBrandTxVariant: String?) -> Bool {
        guard let cardBrandTxVariant = cardBrandTxVariant else {
            return CardSecurityCodeValidator().isValid(securityCode)
        }
        let cardType = CardType(rawValue: cardBrandTxVariant)
        return CardSecurityCodeValidator(cardType: cardType).isValid(securityCode)
    }
}
