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
    
    func test_mapToEnvironment_shouldMapAllEnvironmentsCorrectly() {
        let testCases: [(environment: adyen_checkout.Environment, expected: Adyen.Environment)] = [
            (.test, .test),
            (.europe, .liveEurope),
            (.unitedStates, .liveUnitedStates),
            (.australia, .liveAustralia),
            (.india, .liveIndia),
            (.apse, .liveApse)
        ]
        
        for testCase in testCases {
            let result = testCase.environment.mapToEnvironment()
            XCTAssertEqual(result, testCase.expected, "Failed for environment: \(testCase.environment)")
        }
    }
    
    // MARK: - Amount Mapping Tests
    
    func test_mapToAmount_withEUR_shouldMapCorrectly() {
        let sut = AmountDTO(currency: "EUR", value: 1000)
        
        let result = sut.mapToAmount()
        
        XCTAssertEqual(result.currencyCode, "EUR")
        XCTAssertEqual(result.value, 1000)
    }
    
    func test_mapToAmount_withUSD_shouldMapCorrectly() {
        let sut = AmountDTO(currency: "USD", value: 2500)
        
        let result = sut.mapToAmount()
        
        XCTAssertEqual(result.currencyCode, "USD")
        XCTAssertEqual(result.value, 2500)
    }
    
    // MARK: - FieldVisibility Mapping Tests
    
    func test_toCardFieldVisibility_withShow_shouldReturnShow() {
        let sut = FieldVisibility.show
        
        let result = sut.toCardFieldVisibility()
        
        XCTAssertEqual(result, CardComponent.FieldVisibility.show)
    }
    
    func test_toCardFieldVisibility_withHide_shouldReturnHide() {
        let sut = FieldVisibility.hide
        
        let result = sut.toCardFieldVisibility()
        
        XCTAssertEqual(result, CardComponent.FieldVisibility.hide)
    }
    
    // MARK: - ThreeDS2Configuration Mapping Tests
    
    func test_mapToThreeDS2Configuration_withValidURL_shouldSetRequestorAppURL() {
        let sut = ThreeDS2ConfigurationDTO(requestorAppURL: "https://example.com/3ds2")
        
        let result = sut.mapToThreeDS2Configuration()
        
        XCTAssertEqual(result.requestorAppURL?.absoluteString, "https://example.com/3ds2")
    }
    
    func test_mapToThreeDS2Configuration_withInvalidURL_shouldReturnNilRequestorAppURL() {
        let sut = ThreeDS2ConfigurationDTO(requestorAppURL: "")
        
        let result = sut.mapToThreeDS2Configuration()
        
        XCTAssertNil(result.requestorAppURL)
    }
    
    // MARK: - PaymentResultEnum Mapping Tests
    
    func test_fromError_withComponentCancelled_shouldReturnCancelledByUser() {
        let sut = ComponentError.cancelled
        
        let result = PaymentResultEnum.from(error: sut)
        
        XCTAssertEqual(result, PaymentResultEnum.cancelledByUser)
    }
    
    func test_fromError_withGenericError_shouldReturnError() {
        let sut = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        
        let result = PaymentResultEnum.from(error: sut)
        
        XCTAssertEqual(result, PaymentResultEnum.error)
    }
    
    func test_fromError_withThreeDS2ChallengeCancelled_shouldReturnCancelledByUser() {
        let sut = NSError(
            domain: ADYRuntimeErrorDomain,
            code: Int(ADYRuntimeErrorCode.challengeCancelled.rawValue),
            userInfo: nil
        )
        
        let result = PaymentResultEnum.from(error: sut)
        
        XCTAssertEqual(result, PaymentResultEnum.cancelledByUser)
    }

    // MARK: - ActionComponentConfigurationDTO Tests
    
    func test_createAdyenContext_withDefaultsFromActionComponent_shouldCreateContext() throws {
        let sut = createActionComponentConfigurationDTO()
        
        let result = try sut.createAdyenContext()
        
        XCTAssertNotNil(result)
        XCTAssertNotNil(result.apiContext)
    }
    
    func test_createAdyenContext_withShopperLocale_shouldCreateContext() throws {
        let sut = createActionComponentConfigurationDTO(shopperLocale: "nl-NL")
        
        let result = try sut.createAdyenContext()
        
        XCTAssertNotNil(result)
    }
    
    func test_createAdyenContext_withoutShopperLocale_shouldCreateContext() throws {
        let sut = createActionComponentConfigurationDTO(shopperLocale: nil)
        
        let result = try sut.createAdyenContext()
        
        XCTAssertNotNil(result)
    }
}
