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

extension ConfigurationMapperTests {

    // MARK: - UnencryptedCard Mapping Tests
    
    func test_whenUnencryptedCardDTOProvided_thenMapToCard() {
        let cardDTO = UnencryptedCardDTO(
            cardNumber: "4111111111111111",
            expiryMonth: "03",
            expiryYear: "2030",
            cvc: "737"
        )
        let result = cardDTO.mapToUnencryptedCard()
        XCTAssertEqual(result.number, "4111111111111111")
        XCTAssertEqual(result.expiryMonth, "03")
        XCTAssertEqual(result.expiryYear, "2030")
        XCTAssertEqual(result.securityCode, "737")
    }
    
    func test_whenUnencryptedCardDTOWithNilCvc_thenMapToCardWithNilSecurityCode() {
        let cardDTO = UnencryptedCardDTO(
            cardNumber: "5500000000000004",
            expiryMonth: "12",
            expiryYear: "2025",
            cvc: nil
        )
        let result = cardDTO.mapToUnencryptedCard()
        XCTAssertEqual(result.number, "5500000000000004")
        XCTAssertEqual(result.expiryMonth, "12")
        XCTAssertEqual(result.expiryYear, "2025")
        XCTAssertNil(result.securityCode)
    }
    
    // MARK: - EncryptedCard Mapping Tests
    
    func test_whenEncryptedCardProvided_thenMapToEncryptedCardDTO() {
        let encryptedCard = EncryptedCard(
            number: "encryptedNumber123",
            expiryMonth: "encryptedMonth456",
            expiryYear: "encryptedYear789",
            securityCode: "encryptedCvc000"
        )
        let result = encryptedCard.mapToEncryptedCardDTO()
        XCTAssertEqual(result.encryptedCardNumber, "encryptedNumber123")
        XCTAssertEqual(result.encryptedExpiryMonth, "encryptedMonth456")
        XCTAssertEqual(result.encryptedExpiryYear, "encryptedYear789")
        XCTAssertEqual(result.encryptedSecurityCode, "encryptedCvc000")
    }
    
    func test_whenEncryptedCardHasNilFields_thenMapToEncryptedCardDTOWithNilFields() {
        let encryptedCard = EncryptedCard(
            number: nil,
            expiryMonth: nil,
            expiryYear: nil,
            securityCode: nil
        )
        let result = encryptedCard.mapToEncryptedCardDTO()
        XCTAssertNil(result.encryptedCardNumber)
        XCTAssertNil(result.encryptedExpiryMonth)
        XCTAssertNil(result.encryptedExpiryYear)
        XCTAssertNil(result.encryptedSecurityCode)
    }

    // MARK: - CardConfigurationDTO Mapping Tests
    
    func test_whenCardConfigurationWithShopperLocale_thenLocalizationParametersAreSet() {
        let cardConfig = createCardConfigurationDTO()
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: "nl-NL")
        XCTAssertNotNil(result.localizationParameters)
    }
    
    func test_whenCardConfigurationWithoutShopperLocale_thenLocalizationParametersAreNil() {
        let cardConfig = createCardConfigurationDTO()
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertNil(result.localizationParameters)
    }
    
    func test_whenCardConfigurationHolderNameRequired_thenShowsHolderNameFieldIsTrue() {
        let cardConfig = createCardConfigurationDTO(holderNameRequired: true)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertTrue(result.showsHolderNameField)
    }
    
    func test_whenCardConfigurationHolderNameNotRequired_thenShowsHolderNameFieldIsFalse() {
        let cardConfig = createCardConfigurationDTO(holderNameRequired: false)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertFalse(result.showsHolderNameField)
    }
    
    func test_whenCardConfigurationShowStorePaymentField_thenShowsStorePaymentMethodFieldIsTrue() {
        let cardConfig = createCardConfigurationDTO(showStorePaymentField: true)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertTrue(result.showsStorePaymentMethodField)
    }
    
    func test_whenCardConfigurationShowCvc_thenShowsSecurityCodeFieldIsTrue() {
        let cardConfig = createCardConfigurationDTO(showCvc: true)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertTrue(result.showsSecurityCodeField)
    }
    
    func test_whenCardConfigurationHideCvc_thenShowsSecurityCodeFieldIsFalse() {
        let cardConfig = createCardConfigurationDTO(showCvc: false)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertFalse(result.showsSecurityCodeField)
    }
    
    func test_whenCardConfigurationKcpFieldVisibilityShow_thenKoreanAuthenticationModeIsShow() {
        let cardConfig = createCardConfigurationDTO(kcpFieldVisibility: .show)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertEqual(result.koreanAuthenticationMode, .show)
    }
    
    func test_whenCardConfigurationKcpFieldVisibilityHide_thenKoreanAuthenticationModeIsHide() {
        let cardConfig = createCardConfigurationDTO(kcpFieldVisibility: .hide)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertEqual(result.koreanAuthenticationMode, .hide)
    }
    
    func test_whenCardConfigurationSocialSecurityNumberFieldVisibilityShow_thenSocialSecurityNumberModeIsShow() {
        let cardConfig = createCardConfigurationDTO(socialSecurityNumberFieldVisibility: .show)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertEqual(result.socialSecurityNumberMode, .show)
    }
    
    func test_whenCardConfigurationSocialSecurityNumberFieldVisibilityHide_thenSocialSecurityNumberModeIsHide() {
        let cardConfig = createCardConfigurationDTO(socialSecurityNumberFieldVisibility: .hide)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertEqual(result.socialSecurityNumberMode, .hide)
    }
    
    func test_whenCardConfigurationShowCvcForStoredCard_thenStoredCardConfigurationShowsSecurityCodeField() {
        let cardConfig = createCardConfigurationDTO(showCvcForStoredCard: true)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertTrue(result.storedCardConfiguration.showsSecurityCodeField)
    }
    
    func test_whenCardConfigurationHideCvcForStoredCard_thenStoredCardConfigurationHidesSecurityCodeField() {
        let cardConfig = createCardConfigurationDTO(showCvcForStoredCard: false)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertFalse(result.storedCardConfiguration.showsSecurityCodeField)
    }
    
    // MARK: - AddressMode Mapping Tests
    
    func test_whenAddressModeFull_thenBillingAddressModeIsFull() {
        let cardConfig = createCardConfigurationDTO(addressMode: .full)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertEqual(result.billingAddress.mode, CardComponent.AddressFormType.full)
    }
    
    func test_whenAddressModePostalCode_thenBillingAddressModeIsPostalCode() {
        let cardConfig = createCardConfigurationDTO(addressMode: .postalCode)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertEqual(result.billingAddress.mode, CardComponent.AddressFormType.postalCode)
    }
    
    func test_whenAddressModeNone_thenBillingAddressModeIsNone() {
        let cardConfig = createCardConfigurationDTO(addressMode: .none)
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertEqual(result.billingAddress.mode, CardComponent.AddressFormType.none)
    }
    
    // MARK: - Allowed Card Types Tests
    
    func test_whenSupportedCardTypesProvided_thenAllowedCardTypesAreMapped() {
        let cardConfig = createCardConfigurationDTO(supportedCardTypes: ["visa", "mc", "amex"])
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertNotNil(result.allowedCardTypes)
        XCTAssertEqual(result.allowedCardTypes?.count, 3)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "visa")) ?? false)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "mc")) ?? false)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "amex")) ?? false)
    }
    
    func test_whenSupportedCardTypesEmpty_thenAllowedCardTypesAreNil() {
        let cardConfig = createCardConfigurationDTO(supportedCardTypes: [])
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertNil(result.allowedCardTypes)
    }
    
    func test_whenSupportedCardTypesContainsUppercase_thenCardTypesAreLowercased() {
        let cardConfig = createCardConfigurationDTO(supportedCardTypes: ["VISA", "MC"])
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertNotNil(result.allowedCardTypes)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "visa")) ?? false)
        XCTAssertTrue(result.allowedCardTypes?.contains(CardType(rawValue: "mc")) ?? false)
    }
    
    func test_whenSupportedCardTypesContainsNilValues_thenNilValuesAreFiltered() {
        let cardConfig = createCardConfigurationDTO(supportedCardTypes: ["visa", nil, "mc"])
        let result = cardConfig.mapToCardComponentConfiguration(shopperLocale: nil)
        XCTAssertNotNil(result.allowedCardTypes)
        XCTAssertEqual(result.allowedCardTypes?.count, 2)
    }

    // MARK: - UnencryptedCard Null Handling Tests
    
    func test_whenUnencryptedCardDTOWithNilCardNumber_thenMapToCardWithNilNumber() {
        let cardDTO = UnencryptedCardDTO(
            cardNumber: nil,
            expiryMonth: "03",
            expiryYear: "2030",
            cvc: "737"
        )
        let result = cardDTO.mapToUnencryptedCard()
        XCTAssertNil(result.number)
        XCTAssertEqual(result.expiryMonth, "03")
        XCTAssertEqual(result.expiryYear, "2030")
        XCTAssertEqual(result.securityCode, "737")
    }
    
    func test_whenUnencryptedCardDTOWithNilExpiryMonth_thenMapToCardWithNilExpiryMonth() {
        let cardDTO = UnencryptedCardDTO(
            cardNumber: "4111111111111111",
            expiryMonth: nil,
            expiryYear: "2030",
            cvc: "737"
        )
        let result = cardDTO.mapToUnencryptedCard()
        XCTAssertEqual(result.number, "4111111111111111")
        XCTAssertNil(result.expiryMonth)
        XCTAssertEqual(result.expiryYear, "2030")
    }
    
    func test_whenUnencryptedCardDTOWithNilExpiryYear_thenMapToCardWithNilExpiryYear() {
        let cardDTO = UnencryptedCardDTO(
            cardNumber: "4111111111111111",
            expiryMonth: "03",
            expiryYear: nil,
            cvc: "737"
        )
        let result = cardDTO.mapToUnencryptedCard()
        XCTAssertEqual(result.number, "4111111111111111")
        XCTAssertEqual(result.expiryMonth, "03")
        XCTAssertNil(result.expiryYear)
    }
    
    func test_whenUnencryptedCardDTOWithAllNilFields_thenMapToEmptyCard() {
        let cardDTO = UnencryptedCardDTO(
            cardNumber: nil,
            expiryMonth: nil,
            expiryYear: nil,
            cvc: nil
        )
        let result = cardDTO.mapToUnencryptedCard()
        XCTAssertNil(result.number)
        XCTAssertNil(result.expiryMonth)
        XCTAssertNil(result.expiryYear)
        XCTAssertNil(result.securityCode)
    }
    
    // MARK: - Helper Methods
    
    func createCardConfigurationDTO(
        holderNameRequired: Bool = false,
        addressMode: AddressMode = .none,
        showStorePaymentField: Bool = false,
        showCvcForStoredCard: Bool = true,
        showCvc: Bool = true,
        kcpFieldVisibility: FieldVisibility = .hide,
        socialSecurityNumberFieldVisibility: FieldVisibility = .hide,
        supportedCardTypes: [String?] = []
    ) -> CardConfigurationDTO {
        CardConfigurationDTO(
            holderNameRequired: holderNameRequired,
            addressMode: addressMode,
            showStorePaymentField: showStorePaymentField,
            showCvcForStoredCard: showCvcForStoredCard,
            showCvc: showCvc,
            kcpFieldVisibility: kcpFieldVisibility,
            socialSecurityNumberFieldVisibility: socialSecurityNumberFieldVisibility,
            supportedCardTypes: supportedCardTypes
        )
    }
}
