import XCTest

@testable import adyen_checkout

class CardValidatorTestss: XCTestCase {
    // Card number validation
    func test_given_correctCardNumber_when_validate_then_resultShouldBeValid() {
        let cardNumber = "4111111111111111"

        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: true)

        XCTAssertEqual(validationResult, true)
    }

    func test_given_MCCardNumber_when_validate_then_resultShouldBeValid() {
        let cardNumber = "5454 5454 5454 5454"

        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: true)

        XCTAssertEqual(validationResult, true)
    }

    func test_given_VISACardNumber_when_validate_then_resultShouldBeValid() {
        let cardNumber = "5392 6394 1013 2039"

        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: true)

        XCTAssertEqual(validationResult, true)
    }

    func test_given_AMEXCardNumber_when_validate_then_resultShouldBeValid() {
        let cardNumber = "3795 5311 0957 637"

        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: true)

        XCTAssertEqual(validationResult, true)
    }

    func test_given_incorrectCardNumber_when_validateWithLuhnCheck_then_resultShouldBeInvalid() {
        let cardNumber = "1111 1111 1111 1111"

        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: true)

        XCTAssertEqual(validationResult, false)
    }

    func test_given_cardNumberTooShort_when_validate_then_resultShouldBeInvalid() {
        let cardNumber = "3795 5311"

        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: true)

        XCTAssertEqual(validationResult, false)
    }

    func test_given_cardNumberTooLong_when_validate_then_resultShouldBeInvalid() {
        let cardNumber = "37955311444214324114413423"

        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: true)

        XCTAssertEqual(validationResult, false)
    }

    func test_given_cardNumberWithUnsupportedCharacters_when_validate_then_resultShouldBeInvalid() {
        let cardNumber = "35311TEST-123456"

        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: true)

        XCTAssertEqual(validationResult, false)
    }

    func test_given_emptyCardNumber_when_validate_then_resultShouldBeInvalid() {
        let cardNumber = ""

        let validationResult = CardValidation().validateCardNumber(cardNumber: cardNumber, enableLuhnCheck: true)

        XCTAssertEqual(validationResult, false)
    }

    // Card expiry data validation

    func test_given_validDate_when_validateCardExpiryDate_then_returnValid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "12", expiryYear: "2030")
        XCTAssertEqual(validationResult, true)
    }
    
    func test_given_validShortDate_when_validateCardExpiryDate_then_returnValid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "12", expiryYear: "30")
        XCTAssertEqual(validationResult, true)
    }

    func test_given_dateIsTooFarInTheFuture_when_validateCardExpiryDate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "12", expiryYear: "2099")
        XCTAssertEqual(validationResult, false)
    }

    func test_given_dateIsTooOld_when_validateCardExpiryDate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "12", expiryYear: "2018")
        XCTAssertEqual(validationResult, false)
    }

    func test_given_dateIsEmpty_when_validateCardExpiryDate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "", expiryYear: "")
        XCTAssertEqual(validationResult, false)
    }

    func test_given_dateIsInvalid_when_validateCardExpiryDate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "30", expiryYear: "10")
        XCTAssertEqual(validationResult, false)
    }

    func test_given_monthIsMissing_when_validateCardExpiryDate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "", expiryYear: "10")
        XCTAssertEqual(validationResult, false)
    }

    func test_given_yearIsMissing_when_validateCardExpiryDate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "5", expiryYear: "")
        XCTAssertEqual(validationResult, false)
    }

    func test_given_valuesAreWrong_when_validateCardExpiryDate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "av", expiryYear: "test")
        XCTAssertEqual(validationResult, false)
    }

    func test_given_valuesAreTooLong_when_validateCardExpiryDate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardExpiryDate(expiryMonth: "1234", expiryYear: "56789")
        XCTAssertEqual(validationResult, false)
    }

    // Card security code validation

    func test_given_validSecurityCodeAndVisaCard_when_validate_then_returnValid() {
        let validationResult = CardValidation().validateCardSecurityCode(securityCode: "123", cardBrand: "visa")
        XCTAssertEqual(validationResult, true)
    }

    func test_given_validSecurityCodeAndMasterCard_when_validate_then_returnValid() {
        let validationResult = CardValidation().validateCardSecurityCode(securityCode: "456", cardBrand: "mc")
        XCTAssertEqual(validationResult, true)
    }

    func test_given_validSecurityCodeAndAmexCard_when_validate_then_returnValid() {
        let validationResult = CardValidation().validateCardSecurityCode(securityCode: "1234", cardBrand: "amex")
        XCTAssertEqual(validationResult, true)
    }

    func test_given_invalidSecurityCodeAndVisaCard_when_validate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardSecurityCode(securityCode: "12", cardBrand: "visa")
        XCTAssertEqual(validationResult, false)
    }

    func test_given_invalidSecurityCodeAndMasterCard_when_validate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardSecurityCode(securityCode: "12", cardBrand: "mc")
        XCTAssertEqual(validationResult, false)
    }

    func test_given_validSecurityCodeWithNullCardBrand_when_validate_then_returnValid() {
        let validationResult = CardValidation().validateCardSecurityCode(securityCode: "123", cardBrand: nil)
        XCTAssertEqual(validationResult, true)
    }

    func test_given_validSecurityCodeWithUnsupportedCardBrand_when_validate_then_returnValid() {
        let validationResult = CardValidation().validateCardSecurityCode(securityCode: "123", cardBrand: "")
        XCTAssertEqual(validationResult, true)
    }

    func test_given_invalidSecurityCodeWithNullCardBrand_when_validate_then_returnInvalid() {
        let validationResult = CardValidation().validateCardSecurityCode(securityCode: "1", cardBrand: nil)
        XCTAssertEqual(validationResult, false)
    }
}
