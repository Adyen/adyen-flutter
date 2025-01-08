import Adyen

class CardValidation {
    func validateCardNumber(cardNumber: String, enableLuhnCheck: Bool) -> Bool {
        return CardNumberValidator(isLuhnCheckEnabled: enableLuhnCheck, isEnteredBrandSupported: true).isValid(cardNumber)
    }
}
