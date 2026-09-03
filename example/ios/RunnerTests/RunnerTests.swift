import Adyen
@testable import adyen_checkout
import XCTest

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {
    func test_givenDropInConfigurationDTO_whenMapping_thenCreatesNativeSDKModels() {
        do {
            let dropInConfigurationDTO = createDropInConfigurationDTO(
                countryCode: "US",
                amount: AmountDTO(currency: "USD", value: 1600),
                shopperLocale: "en-US",
                analyticsOptionsDTO: AnalyticsOptionsDTO(enabled: false, version: "0.0.1"),
                showPreselectedStoredPaymentMethod: false
            )

            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            let dropInConfiguration = try dropInConfigurationDTO.createDropInConfiguration(
                payment: Payment(
                    amount: Amount(value: 1600, currencyCode: "USD"),
                    countryCode: "US"
                )
            )

            XCTAssertEqual(adyenContext.apiContext.environment.baseURL, Adyen.Environment.test.baseURL)
            XCTAssertEqual(adyenContext.apiContext.clientKey, testClientKey)
            XCTAssertEqual(adyenContext.payment?.countryCode, "US")
            XCTAssertEqual(adyenContext.payment?.amount.currencyCode, "USD")
            XCTAssertEqual(adyenContext.payment?.amount.value, 1600)
            XCTAssertEqual(dropInConfiguration.allowPreselectedPaymentView, false)
            XCTAssertEqual(dropInConfiguration.allowsSkippingPaymentList, false)
        } catch {
            XCTAssert(false, "Failed")
        }
    }
}
