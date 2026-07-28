import Adyen
@testable import adyen_checkout
import Flutter
import UIKit
import XCTest

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
                isRemoveStoredPaymentMethodEnabled: false,
                isPartialPaymentSupported: true,
                showStoredPaymentMethods: true
            )

            let adyenContext = try dropInConfigurationDTO.createAdyenContext()
            let dropInConfiguration = try dropInConfigurationDTO.createDropInConfiguration(
                payment: Payment(
                    amount: Amount(value: 1600, currencyCode: "USD"),
                    countryCode: "US"
                )
            )

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

    @MainActor
    func testDropInWindowManagerRestoresHostWindowState() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        let hostView = try XCTUnwrap(hostWindow.rootViewController?.view)
        let initialAccessibilityElementsHidden = hostView.accessibilityElementsHidden
        var dropInWindow: UIWindow?
        let manager = DropInWindowManager(
            hostWindowProvider: { hostWindow },
            windowFactory: {
                let window = UIWindow(windowScene: $0)
                dropInWindow = window
                return window
            }
        )
        let rootViewController = MockDropInRootViewController()

        try manager.present(rootViewController: rootViewController)

        XCTAssertEqual(manager.state, .presented)
        XCTAssertEqual(dropInWindow?.windowLevel, .normal)
        XCTAssertTrue(dropInWindow?.isKeyWindow == true)
        XCTAssertTrue(dropInWindow?.accessibilityViewIsModal == true)
        XCTAssertTrue(rootViewController.view.accessibilityViewIsModal)
        XCTAssertTrue(hostView.accessibilityElementsHidden)

        manager.cleanUp()

        XCTAssertEqual(manager.state, .idle)
        XCTAssertEqual(hostView.accessibilityElementsHidden, initialAccessibilityElementsHidden)
        XCTAssertTrue(hostWindow.isKeyWindow)
        XCTAssertTrue(dropInWindow?.isHidden == true)
    }

    @MainActor
    func testDropInWindowManagerRejectsOverlappingPresentations() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        let manager = DropInWindowManager(hostWindowProvider: { hostWindow })
        try manager.present(rootViewController: MockDropInRootViewController())
        defer { manager.cleanUp() }

        XCTAssertThrowsError(try manager.ensureCanPresent())
        XCTAssertEqual(manager.state, .presented)
    }

    @MainActor
    func testDropInWindowManagerPreservesHiddenAccessibilityState() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        let hostView = try XCTUnwrap(hostWindow.rootViewController?.view)
        let initialAccessibilityElementsHidden = hostView.accessibilityElementsHidden
        hostView.accessibilityElementsHidden = true
        defer { hostView.accessibilityElementsHidden = initialAccessibilityElementsHidden }
        let manager = DropInWindowManager(hostWindowProvider: { hostWindow })

        try manager.present(rootViewController: MockDropInRootViewController())
        manager.cleanUp()

        XCTAssertTrue(hostView.accessibilityElementsHidden)
    }

    @MainActor
    func testDropInWindowManagerFailsWithoutWindowScene() {
        let manager = DropInWindowManager(hostWindowProvider: { UIWindow(frame: .zero) })

        XCTAssertThrowsError(try manager.present(rootViewController: MockDropInRootViewController()))
        XCTAssertEqual(manager.state, .idle)
    }

    @MainActor
    func testDropInWindowManagerCoalescesDismissals() async throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        let manager = DropInWindowManager(hostWindowProvider: { hostWindow })
        let rootViewController = MockDropInRootViewController()
        try manager.present(rootViewController: rootViewController)
        let presented = expectation(description: "Child presented")
        rootViewController.present(UIViewController(), animated: false) {
            presented.fulfill()
        }
        await fulfillment(of: [presented], timeout: 1)
        let firstDismissal = expectation(description: "First dismissal completed")
        let secondDismissal = expectation(description: "Second dismissal completed")

        manager.dismiss(animated: false) { firstDismissal.fulfill() }
        manager.dismiss(animated: false) { secondDismissal.fulfill() }
        await fulfillment(of: [firstDismissal, secondDismissal], timeout: 1)

        XCTAssertEqual(manager.state, .idle)
        XCTAssertTrue(hostWindow.isKeyWindow)
    }

    @MainActor
    func testDropInWindowManagerCleansUpWhenSceneDisconnects() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let notificationCenter = NotificationCenter()
        let manager = DropInWindowManager(
            hostWindowProvider: { hostWindow },
            notificationCenter: notificationCenter
        )
        try manager.present(rootViewController: MockDropInRootViewController())

        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)

        XCTAssertEqual(manager.state, .idle)
    }

    @MainActor
    private func activeWindow() -> UIWindow? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        return windows.first(where: \.isKeyWindow) ?? windows.first { !$0.isHidden }
    }
}

private class MockDropInRootViewController: UIViewController, DropInRootViewController {
    func dismissDropIn(animated: Bool, completion: (() -> Void)?) {
        dismiss(animated: animated, completion: completion)
    }
}
