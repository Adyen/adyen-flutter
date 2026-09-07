import Adyen
import AdyenCard

final class CardValidation {
    func validateCardNumber(cardNumber: String, enableLuhnCheck: Bool) -> Bool {
        CardNumberValidator(
            isLuhnCheckEnabled: enableLuhnCheck,
            isEnteredBrandSupported: true
        ).isValid(cardNumber)
    }

    func validateCardExpiryDate(expiryMonth: String, expiryYear: String) -> Bool {
        guard expiryMonth.range(of: #"^\d{2}$"#, options: .regularExpression) != nil,
              expiryYear.range(of: #"^\d{2}$"#, options: .regularExpression) != nil else {
            return false
        }
        return CardExpiryDateValidator().isValid(expiryMonth + expiryYear)
    }

    func validateCardSecurityCode(securityCode: String, cardBrand: String?) -> Bool {
        guard let cardBrand else {
            return CardSecurityCodeValidator().isValid(securityCode)
        }
        return CardSecurityCodeValidator(cardBrand: CardBrand(rawValue: cardBrand)).isValid(securityCode)
    }
}
