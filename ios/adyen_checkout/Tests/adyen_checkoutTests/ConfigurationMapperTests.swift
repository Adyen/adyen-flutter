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

final class ConfigurationMapperTests: XCTestCase {
    
    // MARK: - Environment Mapping Tests
    
    func test_whenEnvironmentIsTest_thenMapToSDKTestEnvironment() {
        let environment = Environment.test
        let result = environment.mapToEnvironment()
        XCTAssertEqual(result, Adyen.Environment.test)
    }
    
    func test_whenEnvironmentIsEurope_thenMapToSDKEuropeEnvironment() {
        let environment = Environment.europe
        let result = environment.mapToEnvironment()
        XCTAssertEqual(result, Adyen.Environment.liveEurope)
    }
    
    func test_whenEnvironmentIsUnitedStates_thenMapToSDKUnitedStatesEnvironment() {
        let environment = Environment.unitedStates
        let result = environment.mapToEnvironment()
        XCTAssertEqual(result, Adyen.Environment.liveUnitedStates)
    }
    
    func test_whenEnvironmentIsAustralia_thenMapToSDKAustraliaEnvironment() {
        let environment = Environment.australia
        let result = environment.mapToEnvironment()
        XCTAssertEqual(result, Adyen.Environment.liveAustralia)
    }
    
    func test_whenEnvironmentIsIndia_thenMapToSDKIndiaEnvironment() {
        let environment = Environment.india
        let result = environment.mapToEnvironment()
        XCTAssertEqual(result, Adyen.Environment.liveIndia)
    }
    
    func test_whenEnvironmentIsApse_thenMapToSDKApseEnvironment() {
        let environment = Environment.apse
        let result = environment.mapToEnvironment()
        XCTAssertEqual(result, Adyen.Environment.liveApse)
    }
    
    // MARK: - Amount Mapping Tests
    
    func test_whenAmountDTOProvided_thenMapToAdyenAmount() {
        let amountDTO = AmountDTO(currency: "EUR", value: 1000)
        let result = amountDTO.mapToAmount()
        XCTAssertEqual(result.currencyCode, "EUR")
        XCTAssertEqual(result.value, 1000)
    }
    
    func test_whenAmountDTOWithDifferentCurrency_thenMapCorrectly() {
        let amountDTO = AmountDTO(currency: "USD", value: 2500)
        let result = amountDTO.mapToAmount()
        XCTAssertEqual(result.currencyCode, "USD")
        XCTAssertEqual(result.value, 2500)
    }
    
    // MARK: - FieldVisibility Mapping Tests
    
    func test_whenFieldVisibilityIsShow_thenMapToCardFieldVisibilityShow() {
        let visibility = FieldVisibility.show
        let result = visibility.toCardFieldVisibility()
        XCTAssertEqual(result, CardComponent.FieldVisibility.show)
    }
    
    func test_whenFieldVisibilityIsHide_thenMapToCardFieldVisibilityHide() {
        let visibility = FieldVisibility.hide
        let result = visibility.toCardFieldVisibility()
        XCTAssertEqual(result, CardComponent.FieldVisibility.hide)
    }
    
    // MARK: - ThreeDS2Configuration Mapping Tests
    
    func test_whenRequestorAppURLProvided_thenMapToThreeDS2Configuration() {
        let threeDS2DTO = ThreeDS2ConfigurationDTO(requestorAppURL: "https://example.com/3ds2")
        let result = threeDS2DTO.mapToThreeDS2Configuration()
        XCTAssertEqual(result.requestorAppURL?.absoluteString, "https://example.com/3ds2")
    }
    
    func test_whenRequestorAppURLIsInvalid_thenReturnDefaultConfiguration() {
        let threeDS2DTO = ThreeDS2ConfigurationDTO(requestorAppURL: "")
        let result = threeDS2DTO.mapToThreeDS2Configuration()
        XCTAssertNil(result.requestorAppURL)
    }
    
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
    
    // MARK: - PaymentResultEnum Mapping Tests
    
    func test_whenComponentErrorCancelled_thenReturnCancelledByUser() {
        let error = ComponentError.cancelled
        let result = PaymentResultEnum.from(error: error)
        XCTAssertEqual(result, PaymentResultEnum.cancelledByUser)
    }
    
    func test_whenGenericError_thenReturnError() {
        let error = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        let result = PaymentResultEnum.from(error: error)
        XCTAssertEqual(result, PaymentResultEnum.error)
    }
    
    func test_whenThreeDS2ChallengeCancel_thenReturnCancelledByUser() {
        let error = NSError(
            domain: ADYRuntimeErrorDomain,
            code: ADYRuntimeErrorCode.challengeCancelled.rawValue,
            userInfo: nil
        )
        let result = PaymentResultEnum.from(error: error)
        XCTAssertEqual(result, PaymentResultEnum.cancelledByUser)
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
    
    // MARK: - DropInConfigurationDTO Tests
    
    func test_whenDropInConfigurationWithDefaults_thenConfigurationIsCreated() throws {
        let dropInConfig = createDropInConfigurationDTO()
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertNotNil(result)
    }
    
    func test_whenDropInConfigurationWithShopperLocale_thenLocalizationParametersAreSet() throws {
        let dropInConfig = createDropInConfigurationDTO(shopperLocale: "de-DE")
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertNotNil(result.localizationParameters)
    }
    
    func test_whenDropInConfigurationWithoutShopperLocale_thenLocalizationParametersAreNil() throws {
        let dropInConfig = createDropInConfigurationDTO(shopperLocale: nil)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertNil(result.localizationParameters)
    }
    
    func test_whenDropInConfigurationSkipListWhenSinglePaymentMethod_thenAllowsSkippingPaymentListIsTrue() throws {
        let dropInConfig = createDropInConfigurationDTO(skipListWhenSinglePaymentMethod: true)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertTrue(result.allowsSkippingPaymentList)
    }
    
    func test_whenDropInConfigurationDoNotSkipListWhenSinglePaymentMethod_thenAllowsSkippingPaymentListIsFalse() throws {
        let dropInConfig = createDropInConfigurationDTO(skipListWhenSinglePaymentMethod: false)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertFalse(result.allowsSkippingPaymentList)
    }
    
    func test_whenDropInConfigurationShowPreselectedStoredPaymentMethod_thenAllowPreselectedPaymentViewIsTrue() throws {
        let dropInConfig = createDropInConfigurationDTO(showPreselectedStoredPaymentMethod: true)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertTrue(result.allowPreselectedPaymentView)
    }
    
    func test_whenDropInConfigurationHidePreselectedStoredPaymentMethod_thenAllowPreselectedPaymentViewIsFalse() throws {
        let dropInConfig = createDropInConfigurationDTO(showPreselectedStoredPaymentMethod: false)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertFalse(result.allowPreselectedPaymentView)
    }
    
    func test_whenDropInConfigurationIsRemoveStoredPaymentMethodEnabled_thenAllowDisablingStoredPaymentMethodsIsTrue() throws {
        let dropInConfig = createDropInConfigurationDTO(isRemoveStoredPaymentMethodEnabled: true)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertTrue(result.paymentMethodsList.allowDisablingStoredPaymentMethods)
    }
    
    func test_whenDropInConfigurationIsRemoveStoredPaymentMethodDisabled_thenAllowDisablingStoredPaymentMethodsIsFalse() throws {
        let dropInConfig = createDropInConfigurationDTO(isRemoveStoredPaymentMethodEnabled: false)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertFalse(result.paymentMethodsList.allowDisablingStoredPaymentMethods)
    }
    
    func test_whenDropInConfigurationWithCardConfiguration_thenCardConfigurationIsSet() throws {
        let cardConfig = createCardConfigurationDTO(holderNameRequired: true)
        let dropInConfig = createDropInConfigurationDTO(cardConfigurationDTO: cardConfig)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertTrue(result.card.showsHolderNameField)
    }
    
    func test_whenDropInConfigurationWithTwintConfiguration_thenTwintConfigurationIsSet() throws {
        let twintConfig = TwintConfigurationDTO(iosCallbackAppScheme: "myapp", showStorePaymentField: true)
        let dropInConfig = createDropInConfigurationDTO(twintConfigurationDTO: twintConfig)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertEqual(result.actionComponent.twint.callbackAppScheme, "myapp")
    }
    
    func test_whenDropInConfigurationWithThreeDS2Configuration_thenThreeDS2ConfigurationIsSet() throws {
        let threeDS2Config = ThreeDS2ConfigurationDTO(requestorAppURL: "https://example.com/3ds2")
        let dropInConfig = createDropInConfigurationDTO(threeDS2ConfigurationDTO: threeDS2Config)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertEqual(result.actionComponent.threeDS.requestorAppURL?.absoluteString, "https://example.com/3ds2")
    }
    
    func test_whenDropInConfigurationWithCashAppPayConfiguration_thenCashAppPayConfigurationIsSet() throws {
        let cashAppPayConfig = CashAppPayConfigurationDTO(cashAppPayEnvironment: .sandbox, returnUrl: "myapp://cashapp")
        let dropInConfig = createDropInConfigurationDTO(cashAppPayConfigurationDTO: cashAppPayConfig)
        let result = try dropInConfig.createDropInConfiguration(payment: nil)
        XCTAssertEqual(result.cashAppPay?.redirectURL, URL(string: "myapp://cashapp"))
    }
    
    // MARK: - AdyenContext Tests
    
    func test_whenDropInConfigurationCreateAdyenContext_thenContextIsCreated() throws {
        let dropInConfig = createDropInConfigurationDTO()
        let result = try dropInConfig.createAdyenContext()
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.apiContext)
    }
    
    func test_whenDropInConfigurationWithAmountAndCountryCode_thenPaymentIsSet() throws {
        let amount = AmountDTO(currency: "EUR", value: 1000)
        let dropInConfig = createDropInConfigurationDTO(amount: amount, countryCode: "NL")
        let result = try dropInConfig.createAdyenContext()
        XCTAssertNotNil(result.payment)
        XCTAssertEqual(result.payment?.amount.currencyCode, "EUR")
        XCTAssertEqual(result.payment?.amount.value, 1000)
        XCTAssertEqual(result.payment?.countryCode, "NL")
    }
    
    func test_whenDropInConfigurationWithoutAmount_thenPaymentIsNil() throws {
        let dropInConfig = createDropInConfigurationDTO(amount: nil, countryCode: "NL")
        let result = try dropInConfig.createAdyenContext()
        XCTAssertNil(result.payment)
    }
    
    func test_whenDropInConfigurationWithAnalyticsEnabled_thenAnalyticsIsEnabled() throws {
        let analyticsOptions = AnalyticsOptionsDTO(enabled: true, version: "1.0.0")
        let dropInConfig = createDropInConfigurationDTO(analyticsOptionsDTO: analyticsOptions)
        let result = try dropInConfig.createAdyenContext()
        XCTAssertTrue(result.analyticsConfiguration?.isEnabled ?? false)
    }
    
    func test_whenDropInConfigurationWithAnalyticsDisabled_thenAnalyticsIsDisabled() throws {
        let analyticsOptions = AnalyticsOptionsDTO(enabled: false, version: "1.0.0")
        let dropInConfig = createDropInConfigurationDTO(analyticsOptionsDTO: analyticsOptions)
        let result = try dropInConfig.createAdyenContext()
        XCTAssertFalse(result.analyticsConfiguration?.isEnabled ?? true)
    }
    
    // MARK: - ActionComponentConfigurationDTO Tests
    
    func test_whenActionComponentConfigurationCreateAdyenContext_thenContextIsCreated() throws {
        let actionConfig = createActionComponentConfigurationDTO()
        let result = try actionConfig.createAdyenContext()
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.apiContext)
    }
    
    func test_whenActionComponentConfigurationWithShopperLocale_thenContextIsCreated() throws {
        let actionConfig = createActionComponentConfigurationDTO(shopperLocale: "nl-NL")
        let result = try actionConfig.createAdyenContext()
        XCTAssertNotNil(result)
    }
    
    func test_whenActionComponentConfigurationWithoutShopperLocale_thenContextIsCreated() throws {
        let actionConfig = createActionComponentConfigurationDTO(shopperLocale: nil)
        let result = try actionConfig.createAdyenContext()
        XCTAssertNotNil(result)
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
    
    private func createActionComponentConfigurationDTO(
        environment: Environment = .test,
        clientKey: String = "test_client_key",
        shopperLocale: String? = nil,
        amount: AmountDTO? = nil,
        analyticsOptionsDTO: AnalyticsOptionsDTO = AnalyticsOptionsDTO(enabled: true, version: "1.0.0")
    ) -> ActionComponentConfigurationDTO {
        ActionComponentConfigurationDTO(
            environment: environment,
            clientKey: clientKey,
            shopperLocale: shopperLocale,
            amount: amount,
            analyticsOptionsDTO: analyticsOptionsDTO
        )
    }
    
    private func createCardConfigurationDTO(
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
    
    private func createDropInConfigurationDTO(
        environment: Environment = .test,
        clientKey: String = "test_client_key",
        countryCode: String = "NL",
        amount: AmountDTO? = AmountDTO(currency: "EUR", value: 1000),
        shopperLocale: String? = nil,
        cardConfigurationDTO: CardConfigurationDTO? = nil,
        applePayConfigurationDTO: ApplePayConfigurationDTO? = nil,
        cashAppPayConfigurationDTO: CashAppPayConfigurationDTO? = nil,
        twintConfigurationDTO: TwintConfigurationDTO? = nil,
        threeDS2ConfigurationDTO: ThreeDS2ConfigurationDTO? = nil,
        analyticsOptionsDTO: AnalyticsOptionsDTO = AnalyticsOptionsDTO(enabled: true, version: "1.0.0"),
        showPreselectedStoredPaymentMethod: Bool = true,
        skipListWhenSinglePaymentMethod: Bool = false,
        isRemoveStoredPaymentMethodEnabled: Bool = false
    ) -> DropInConfigurationDTO {
        DropInConfigurationDTO(
            environment: environment,
            clientKey: clientKey,
            countryCode: countryCode,
            amount: amount,
            shopperLocale: shopperLocale,
            cardConfigurationDTO: cardConfigurationDTO,
            applePayConfigurationDTO: applePayConfigurationDTO,
            googlePayConfigurationDTO: nil,
            cashAppPayConfigurationDTO: cashAppPayConfigurationDTO,
            twintConfigurationDTO: twintConfigurationDTO,
            threeDS2ConfigurationDTO: threeDS2ConfigurationDTO,
            analyticsOptionsDTO: analyticsOptionsDTO,
            showPreselectedStoredPaymentMethod: showPreselectedStoredPaymentMethod,
            skipListWhenSinglePaymentMethod: skipListWhenSinglePaymentMethod,
            isRemoveStoredPaymentMethodEnabled: isRemoveStoredPaymentMethodEnabled,
            preselectedPaymentMethodTitle: nil,
            paymentMethodNames: nil,
            isPartialPaymentSupported: false
        )
    }
}
