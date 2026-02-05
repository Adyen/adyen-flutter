@_spi(AdyenInternal) import Adyen
@testable import adyen_checkout
import XCTest

#if canImport(AdyenCard)
    import AdyenCard
#endif
#if canImport(AdyenEncryption)
    import AdyenEncryption
#endif
#if canImport(AdyenActions)
    import AdyenActions
#endif
#if canImport(Adyen3DS2)
    import Adyen3DS2
#endif

@testable import AdyenEncryption


extension ConfigurationMapperTests {

    // MARK: - UnencryptedCard Mapping Tests
    
    func test_mapToUnencryptedCard_withAllFields_shouldMapCorrectly() {
        let sut = UnencryptedCardDTO(
            cardNumber: "4111111111111111",
            expiryMonth: "03",
            expiryYear: "2030",
            cvc: "737"
        )
        
        let result = sut.mapToUnencryptedCard()
        
        XCTAssertEqual(result.number, "4111111111111111")
        XCTAssertEqual(result.expiryMonth, "03")
        XCTAssertEqual(result.expiryYear, "2030")
        XCTAssertEqual(result.securityCode, "737")
    }
    
    func test_mapToUnencryptedCard_withNilCvc_shouldMapWithNilSecurityCode() {
        let sut = UnencryptedCardDTO(
            cardNumber: "5500000000000004",
            expiryMonth: "12",
            expiryYear: "2025",
            cvc: nil
        )
        
        let result = sut.mapToUnencryptedCard()
        
        XCTAssertEqual(result.number, "5500000000000004")
        XCTAssertEqual(result.expiryMonth, "12")
        XCTAssertEqual(result.expiryYear, "2025")
        XCTAssertNil(result.securityCode)
    }
    
    // MARK: - EncryptedCard Mapping Tests
    
    func test_mapToEncryptedCardDTO_withAllFields_shouldMapCorrectly() {
        let sut = EncryptedCard(
            number: "encryptedNumber123",
            securityCode: "encryptedCvc000",
            expiryMonth: "encryptedMonth456",
            expiryYear: "encryptedYear789"
        )
        
        let result = sut.mapToEncryptedCardDTO()
        
        XCTAssertEqual(result.encryptedCardNumber, "encryptedNumber123")
        XCTAssertEqual(result.encryptedExpiryMonth, "encryptedMonth456")
        XCTAssertEqual(result.encryptedExpiryYear, "encryptedYear789")
        XCTAssertEqual(result.encryptedSecurityCode, "encryptedCvc000")
    }
    
    func test_mapToEncryptedCardDTO_withNilFields_shouldMapWithNilFields() {
        let sut = EncryptedCard(
            number: nil,
            securityCode: nil,
            expiryMonth: nil,
            expiryYear: nil
        )
        
        let result = sut.mapToEncryptedCardDTO()
        
        XCTAssertNil(result.encryptedCardNumber)
        XCTAssertNil(result.encryptedExpiryMonth)
        XCTAssertNil(result.encryptedExpiryYear)
        XCTAssertNil(result.encryptedSecurityCode)
    }

    // MARK: - CardConfigurationDTO Mapping Tests
    
    func test_localizationParameters_withShopperLocale_shouldBeSet() {
        let sut = createCardConfigurationDTO()
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: "nl-NL")
        
        XCTAssertNotNil(result.localizationParameters)
    }
    
    func test_localizationParameters_withoutShopperLocale_shouldBeNil() {
        let sut = createCardConfigurationDTO()
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertNil(result.localizationParameters)
    }
    
    func test_showsHolderNameField_withRequired_shouldBeTrue() {
        let sut = createCardConfigurationDTO(holderNameRequired: true)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertTrue(result.showsHolderNameField)
    }
    
    func test_showsHolderNameField_withNotRequired_shouldBeFalse() {
        let sut = createCardConfigurationDTO(holderNameRequired: false)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertFalse(result.showsHolderNameField)
    }
    
    func test_showsStorePaymentMethodField_withEnabled_shouldBeTrue() {
        let sut = createCardConfigurationDTO(showStorePaymentField: true)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertTrue(result.showsStorePaymentMethodField)
    }
    
    func test_showsSecurityCodeField_withShow_shouldBeTrue() {
        let sut = createCardConfigurationDTO(showCvc: true)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertTrue(result.showsSecurityCodeField)
    }
    
    func test_showsSecurityCodeField_withHide_shouldBeFalse() {
        let sut = createCardConfigurationDTO(showCvc: false)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertFalse(result.showsSecurityCodeField)
    }
    
    func test_koreanAuthenticationMode_withShow_shouldBeShow() {
        let sut = createCardConfigurationDTO(kcpFieldVisibility: .show)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertEqual(result.koreanAuthenticationMode, .show)
    }
    
    func test_koreanAuthenticationMode_withHide_shouldBeHide() {
        let sut = createCardConfigurationDTO(kcpFieldVisibility: .hide)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertEqual(result.koreanAuthenticationMode, .hide)
    }
    
    func test_socialSecurityNumberMode_withShow_shouldBeShow() {
        let sut = createCardConfigurationDTO(socialSecurityNumberFieldVisibility: .show)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertEqual(result.socialSecurityNumberMode, .show)
    }
    
    func test_socialSecurityNumberMode_withHide_shouldBeHide() {
        let sut = createCardConfigurationDTO(socialSecurityNumberFieldVisibility: .hide)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertEqual(result.socialSecurityNumberMode, .hide)
    }
    
    func test_storedCardShowsSecurityCodeField_withShow_shouldBeTrue() {
        let sut = createCardConfigurationDTO(showCvcForStoredCard: true)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertTrue(result.stored.showsSecurityCodeField)
    }
    
    func test_storedCardShowsSecurityCodeField_withHide_shouldBeFalse() {
        let sut = createCardConfigurationDTO(showCvcForStoredCard: false)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertFalse(result.stored.showsSecurityCodeField)
    }
    
    // MARK: - AddressMode Mapping Tests
    
    func test_billingAddressMode_withFull_shouldBeFull() {
        let sut = createCardConfigurationDTO(addressMode: .full)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertEqual(result.billingAddress.mode, CardComponent.AddressFormType.full)
    }
    
    func test_billingAddressMode_withPostalCode_shouldBePostalCode() {
        let sut = createCardConfigurationDTO(addressMode: .postalCode)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertEqual(result.billingAddress.mode, CardComponent.AddressFormType.postalCode)
    }
    
    func test_billingAddressMode_withNone_shouldBeNone() {
        let sut = createCardConfigurationDTO(addressMode: .none)
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertEqual(result.billingAddress.mode, CardComponent.AddressFormType.none)
    }
    
    // MARK: - Allowed Card Types Tests
    
    func test_allowedCardTypes_withMultipleTypes_shouldMapAll() {
        let sut = createCardConfigurationDTO(supportedCardTypes: ["visa", "mc", "amex"])
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertNotNil(result.allowedCardTypes)
        XCTAssertEqual(result.allowedCardTypes?.count, 3)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "visa")) ?? false)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "mc")) ?? false)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "amex")) ?? false)
    }
    
    func test_allowedCardTypes_withEmptyList_shouldBeNil() {
        let sut = createCardConfigurationDTO(supportedCardTypes: [])
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertNil(result.allowedCardTypes)
    }
    
    func test_allowedCardTypes_withUppercase_shouldBeLowercased() {
        let sut = createCardConfigurationDTO(supportedCardTypes: ["VISA", "MC"])
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertNotNil(result.allowedCardTypes)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "visa")) ?? false)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "mc")) ?? false)
    }
    
    func test_allowedCardTypes_withNilValues_shouldFilterNils() {
        let sut = createCardConfigurationDTO(supportedCardTypes: ["visa", nil, "mc"])
        
        let result = sut.mapToCardComponentConfiguration(shopperLocale: nil)
        
        XCTAssertNotNil(result.allowedCardTypes)
        XCTAssertEqual(result.allowedCardTypes?.count, 2)
    }

    // MARK: - UnencryptedCard Null Handling Tests
    
    func test_mapToUnencryptedCard_withNilCardNumber_shouldMapWithNilNumber() {
        let sut = UnencryptedCardDTO(
            cardNumber: nil,
            expiryMonth: "03",
            expiryYear: "2030",
            cvc: "737"
        )
        
        let result = sut.mapToUnencryptedCard()
        
        XCTAssertNil(result.number)
        XCTAssertEqual(result.expiryMonth, "03")
        XCTAssertEqual(result.expiryYear, "2030")
        XCTAssertEqual(result.securityCode, "737")
    }
    
    func test_mapToUnencryptedCard_withNilExpiryMonth_shouldMapWithNilExpiryMonth() {
        let sut = UnencryptedCardDTO(
            cardNumber: "4111111111111111",
            expiryMonth: nil,
            expiryYear: "2030",
            cvc: "737"
        )
        
        let result = sut.mapToUnencryptedCard()
        
        XCTAssertEqual(result.number, "4111111111111111")
        XCTAssertNil(result.expiryMonth)
        XCTAssertEqual(result.expiryYear, "2030")
    }
    
    func test_mapToUnencryptedCard_withNilExpiryYear_shouldMapWithNilExpiryYear() {
        let sut = UnencryptedCardDTO(
            cardNumber: "4111111111111111",
            expiryMonth: "03",
            expiryYear: nil,
            cvc: "737"
        )
        
        let result = sut.mapToUnencryptedCard()
        
        XCTAssertEqual(result.number, "4111111111111111")
        XCTAssertEqual(result.expiryMonth, "03")
        XCTAssertNil(result.expiryYear)
    }
    
    func test_mapToUnencryptedCard_withAllNilFields_shouldMapToEmptyCard() {
        let sut = UnencryptedCardDTO(
            cardNumber: nil,
            expiryMonth: nil,
            expiryYear: nil,
            cvc: nil
        )
        
        let result = sut.mapToUnencryptedCard()
        
        XCTAssertNil(result.number)
        XCTAssertNil(result.expiryMonth)
        XCTAssertNil(result.expiryYear)
        XCTAssertNil(result.securityCode)
    }
}
