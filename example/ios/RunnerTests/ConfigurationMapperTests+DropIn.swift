@_spi(AdyenInternal) import Adyen
@_spi(AdyenInternal) import AdyenNetworking
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
    
    func test_createDropInConfiguration_withDefaults_shouldSucceed() throws {
        let sut = createDropInConfigurationDTO()
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertNotNil(result)
    }
    
    func test_localizationParameters_withShopperLocaleInDTO_shouldBeSet() throws {
        let sut = createDropInConfigurationDTO(shopperLocale: "de-DE")
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertNotNil(result.localizationParameters)
    }
    
    func test_localizationParameters_withoutShopperLocaleInDTO_shouldBeNil() throws {
        let sut = createDropInConfigurationDTO(shopperLocale: nil)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertNil(result.localizationParameters)
    }
    
    func test_allowsSkippingPaymentList_withSkipEnabled_shouldBeTrue() throws {
        let sut = createDropInConfigurationDTO(skipListWhenSinglePaymentMethod: true)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertTrue(result.allowsSkippingPaymentList)
    }
    
    func test_allowsSkippingPaymentList_withSkipDisabled_shouldBeFalse() throws {
        let sut = createDropInConfigurationDTO(skipListWhenSinglePaymentMethod: false)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertFalse(result.allowsSkippingPaymentList)
    }
    
    func test_allowPreselectedPaymentView_withShow_shouldBeTrue() throws {
        let sut = createDropInConfigurationDTO(showPreselectedStoredPaymentMethod: true)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertTrue(result.allowPreselectedPaymentView)
    }
    
    func test_allowPreselectedPaymentView_withHide_shouldBeFalse() throws {
        let sut = createDropInConfigurationDTO(showPreselectedStoredPaymentMethod: false)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertFalse(result.allowPreselectedPaymentView)
    }
    
    func test_allowDisablingStoredPaymentMethods_withEnabled_shouldBeTrue() throws {
        let sut = createDropInConfigurationDTO(isRemoveStoredPaymentMethodEnabled: true)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertTrue(result.paymentMethodsList.allowDisablingStoredPaymentMethods)
    }
    
    func test_allowDisablingStoredPaymentMethods_withDisabled_shouldBeFalse() throws {
        let sut = createDropInConfigurationDTO(isRemoveStoredPaymentMethodEnabled: false)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertFalse(result.paymentMethodsList.allowDisablingStoredPaymentMethods)
    }
    
    func test_cardConfiguration_withHolderNameRequired_shouldBeSet() throws {
        let cardConfig = createCardConfigurationDTO(holderNameRequired: true)
        let sut = createDropInConfigurationDTO(cardConfigurationDTO: cardConfig)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertTrue(result.card.showsHolderNameField)
    }
    
    func test_twintConfiguration_withCallbackAppScheme_shouldBeSet() throws {
        let twintConfig = TwintConfigurationDTO(iosCallbackAppScheme: "myapp", showStorePaymentField: true)
        let sut = createDropInConfigurationDTO(twintConfigurationDTO: twintConfig)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertEqual(result.actionComponent.twint?.callbackAppScheme, "myapp")
    }
    
    func test_threeDS2Configuration_withRequestorAppURL_shouldBeSet() throws {
        let threeDS2Config = ThreeDS2ConfigurationDTO(requestorAppURL: "https://example.com/3ds2")
        let sut = createDropInConfigurationDTO(threeDS2ConfigurationDTO: threeDS2Config)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertEqual(result.actionComponent.threeDS.requestorAppURL?.absoluteString, "https://example.com/3ds2")
    }
    
    func test_cashAppPayConfiguration_withReturnUrl_shouldBeSet() throws {
        let cashAppPayConfig = CashAppPayConfigurationDTO(cashAppPayEnvironment: .sandbox, returnUrl: "myapp://cashapp")
        let sut = createDropInConfigurationDTO(cashAppPayConfigurationDTO: cashAppPayConfig)
        
        let result = try sut.createDropInConfiguration(payment: nil)
        
        XCTAssertEqual(result.cashAppPay?.redirectURL, URL(string: "myapp://cashapp"))
    }
    
    // MARK: - AdyenContext Tests
    
    func test_createAdyenContext_withDefaults_shouldCreateContext() throws {
        let sut = createDropInConfigurationDTO()
        
        let result = try sut.createAdyenContext()
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.apiContext)
    }
    
    func test_payment_withAmountAndCountryCode_shouldBeSet() throws {
        let amount = AmountDTO(currency: "EUR", value: 1000)
        let sut = createDropInConfigurationDTO(countryCode: "NL", amount: amount)
        
        let result = try sut.createAdyenContext()
        
        XCTAssertNotNil(result.payment)
        XCTAssertEqual(result.payment?.amount.currencyCode, "EUR")
        XCTAssertEqual(result.payment?.amount.value, 1000)
        XCTAssertEqual(result.payment?.countryCode, "NL")
    }
    
    func test_payment_withoutAmount_shouldBeNil() throws {
        let sut = createDropInConfigurationDTO(countryCode: "NL", amount: nil)
        
        let result = try sut.createAdyenContext()
        
        XCTAssertNil(result.payment)
    }
}
