import Adyen
@testable import adyen_checkout
import PassKit
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

    func test_omittedShippingContactEditingUsesPassKitDefault() throws {
        let request = try makeApplePayPaymentRequest(
            dto: ApplePayConfigurationDTO(
                merchantId: "",
                merchantName: "Test Merchant",
                hasOnSelectShippingMethod: false,
                hasOnSelectShippingContact: false,
                hasOnChangeCouponCode: false,
                hasOnAuthorize: false
            ),
            amount: Adyen.Amount(value: 11295, currencyCode: "EUR"),
            countryCode: "NL"
        )

        XCTAssertEqual(request.shippingContactEditingMode.rawValue, 1)
    }

    @MainActor
    func test_applePayButtonRendersBeforePaymentComponentCreation() {
        let paymentView = CheckoutPaymentView(
            checkoutId: "checkout-id",
            componentId: "component-id",
            paymentMethodJson: #"{"type":"applepay"}"#,
            isStoredPaymentMethod: false,
            applePayButtonTheme: "white",
            applePayButtonType: "buy",
            applePayButtonCornerRadius: 8,
            applePayButtonWidth: 180,
            applePayButtonHeight: 48,
            holder: CheckoutHolder(),
            events: ComponentPlatformEventHandler()
        )

        let button = paymentView.view().subviews
            .flatMap(\.subviews)
            .compactMap { $0 as? PKPaymentButton }
            .first

        XCTAssertNotNil(button)
        XCTAssertEqual(button?.cornerRadius, 8)
    }
}
