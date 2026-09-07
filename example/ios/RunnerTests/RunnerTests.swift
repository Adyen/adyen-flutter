@testable import adyen_checkout
import XCTest

final class RunnerTests: XCTestCase {
    func test_generatedCheckoutEventCarriesCheckoutIdentity() {
        let event = CheckoutEventDTO(
            type: .componentReady,
            checkoutId: "checkout-id",
            componentId: "component-id",
            requiresUserInteraction: true
        )

        XCTAssertEqual(event.checkoutId, "checkout-id")
        XCTAssertEqual(event.componentId, "component-id")
        XCTAssertEqual(event.requiresUserInteraction, true)
    }
}
