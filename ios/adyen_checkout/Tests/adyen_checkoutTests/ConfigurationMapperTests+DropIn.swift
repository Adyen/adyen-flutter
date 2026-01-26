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
    
    // MARK: - Helper Methods
    
    func createDropInConfigurationDTO(
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
