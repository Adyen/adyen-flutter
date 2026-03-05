@_spi(AdyenInternal) import Adyen
@testable import adyen_checkout
import XCTest

#if canImport(AdyenComponents)
    import AdyenComponents
#endif

extension ConfigurationMapperTests {
    // MARK: - BlikComponentConfigurationDTO.createAdyenContext Tests

    func test_blik_createAdyenContext_withDefaults_shouldCreateContext() throws {
        let sut = createBlikComponentConfigurationDTO()

        let result = try sut.createAdyenContext()

        XCTAssertNotNil(result)
        XCTAssertNotNil(result.apiContext)
    }

    func test_blik_createAdyenContext_withAmountAndCountryCode_shouldSetPayment() throws {
        let amount = AmountDTO(currency: "PLN", value: 1000)
        let sut = createBlikComponentConfigurationDTO(countryCode: "PL", amount: amount)

        let result = try sut.createAdyenContext()

        XCTAssertNotNil(result.payment)
        XCTAssertEqual(result.payment?.amount.currencyCode, "PLN")
        XCTAssertEqual(result.payment?.amount.value, 1000)
        XCTAssertEqual(result.payment?.countryCode, "PL")
    }

    func test_blik_createAdyenContext_withoutAmount_shouldHaveNilPayment() throws {
        let sut = createBlikComponentConfigurationDTO(amount: nil)

        let result = try sut.createAdyenContext()

        XCTAssertNil(result.payment)
    }

    func test_blik_createAdyenContext_withTestEnvironment_shouldUseTestBaseURL() throws {
        let sut = createBlikComponentConfigurationDTO(environment: .test)

        let result = try sut.createAdyenContext()

        XCTAssertEqual(result.apiContext.environment.baseURL, Adyen.Environment.test.baseURL)
    }

    // MARK: - BlikComponentConfigurationDTO.mapToBlikComponentConfiguration Tests

    func test_blik_localizationParameters_withShopperLocale_shouldBeSet() {
        let sut = createBlikComponentConfigurationDTO(shopperLocale: "pl-PL")

        let result = sut.mapToBlikComponentConfiguration()

        XCTAssertNotNil(result.localizationParameters)
    }

    func test_blik_localizationParameters_withoutShopperLocale_shouldBeNil() {
        let sut = createBlikComponentConfigurationDTO(shopperLocale: nil)

        let result = sut.mapToBlikComponentConfiguration()

        XCTAssertNil(result.localizationParameters)
    }
}
