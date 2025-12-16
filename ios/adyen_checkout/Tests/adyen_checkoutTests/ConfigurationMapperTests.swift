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
    
}
