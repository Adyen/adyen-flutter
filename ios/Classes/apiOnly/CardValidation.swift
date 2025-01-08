import Adyen

class CardValidation {
    func validateCardNumber(cardNumber: String, enableLuhnCheck: Bool) -> Bool {
        return CardNumberValidator(isLuhnCheckEnabled: enableLuhnCheck, isEnteredBrandSupported: true).isValid(cardNumber)
    }
    
    func validateCardExpiryDate(expiryMonth: String, expiryYear: String) -> Bool {
        print("\(expiryMonth)\(expiryYear)")
        //return CardExpiryDateValidator().isValid("\(expiryMonth)\(expiryYear)")
        return CardExpiryDateValidator().isValid("0330")
    }
}
