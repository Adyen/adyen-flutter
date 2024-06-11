import Adyen
import Flutter
import UIKit
import XCTest

@testable import adyen_checkout

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {
    private let TEST_CLIENT_KEY = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

    func testWhenDropInConfigurationDtoIsProvidedThenMapItToNativeSdkModel() {
        do {
            let dropInConfigurationDTO = DropInConfigurationDTO(
                environment: Environment.test,
                clientKey: TEST_CLIENT_KEY,
                countryCode: "US",
                amount: AmountDTO(currency: "USD", value: 1600),
                shopperLocale: "en-US",
                analyticsOptionsDTO: AnalyticsOptionsDTO(enabled: false, version: "0.0.1"),
                showPreselectedStoredPaymentMethod: false,
                skipListWhenSinglePaymentMethod: false,
                isRemoveStoredPaymentMethodEnabled: false
            )

            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            let dropInConfiguration = try dropInConfigurationDTO.createDropInConfiguration(payment: Payment(amount: Amount(value: 1600, currencyCode: "USD"), countryCode: "US"))

            XCTAssertEqual(adyenContext.apiContext.environment.baseURL, Adyen.Environment.test.baseURL)
            XCTAssertEqual(adyenContext.apiContext.clientKey, TEST_CLIENT_KEY)
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
