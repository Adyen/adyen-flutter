import Adyen
@testable import adyen_checkout
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif
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
            let dropInConfigurationDTO = makeDropInConfigurationDTO()

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
        defer { hostView.accessibilityElementsHidden = initialAccessibilityElementsHidden }
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
        XCTAssertEqual(dropInWindow?.windowLevel.rawValue, UIWindow.Level.normal.rawValue + 1)
        XCTAssertTrue(dropInWindow?.isKeyWindow == true)
        XCTAssertTrue(rootViewController.hostViewController === hostWindow.rootViewController)
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
        XCTAssertThrowsError(try manager.present(rootViewController: MockDropInRootViewController()))
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
    func testDropInWindowManagerCoalescesDismissals() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        let manager = DropInWindowManager(hostWindowProvider: { hostWindow })
        let rootViewController = MockDropInRootViewController()
        rootViewController.stubbedPresentedViewController = UIViewController()
        try manager.present(rootViewController: rootViewController)
        var completedDismissals = 0

        manager.dismiss(animated: false) { completedDismissals += 1 }
        manager.dismiss(animated: false) { completedDismissals += 1 }

        // Both requests wait on the single underlying dismissal rather than starting a second one.
        XCTAssertEqual(manager.state, .dismissing)
        XCTAssertEqual(rootViewController.dismissDropInCallCount, 1)
        XCTAssertEqual(completedDismissals, 0)

        rootViewController.completePendingDismissal()

        XCTAssertEqual(manager.state, .idle)
        XCTAssertEqual(completedDismissals, 2)
        XCTAssertTrue(hostWindow.isKeyWindow)
    }

    @MainActor
    func testDropInWindowManagerCleansUpWhenSceneDisconnects() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        // The scene disconnect path deliberately leaves the key window untouched, so restore it here to
        // keep the host application usable for the remaining tests.
        defer { hostWindow.makeKey() }
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let notificationCenter = NotificationCenter()
        let manager = DropInWindowManager(
            hostWindowProvider: { hostWindow },
            notificationCenter: notificationCenter
        )
        var unexpectedDismissals = 0
        manager.onUnexpectedDismissal = { unexpectedDismissals += 1 }
        try manager.present(rootViewController: MockDropInRootViewController())

        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)

        XCTAssertEqual(manager.state, .idle)
        XCTAssertEqual(unexpectedDismissals, 1)
    }

    @MainActor
    func testDropInWindowManagerDoesNotReportUnexpectedDismissalWhenDismissalWasRequested() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let notificationCenter = NotificationCenter()
        let manager = DropInWindowManager(
            hostWindowProvider: { hostWindow },
            notificationCenter: notificationCenter
        )
        var unexpectedDismissals = 0
        manager.onUnexpectedDismissal = { unexpectedDismissals += 1 }
        let rootViewController = MockDropInRootViewController()
        rootViewController.stubbedPresentedViewController = UIViewController()
        try manager.present(rootViewController: rootViewController)
        // Dismissal is requested but never completed by UIKit, leaving the manager mid-dismissal.
        manager.dismiss(animated: false)

        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)

        XCTAssertEqual(manager.state, .idle)
        XCTAssertEqual(unexpectedDismissals, 0)
    }

    @MainActor
    func testDropInViewControllerMirrorsHostViewControllerTraits() throws {
        let sut = try DropInViewController(dropInComponent: makeDropInComponent())
        // Held strongly for the duration of the test, mirroring the host window retaining its root view controller.
        let hostViewController = MockHostViewController()

        XCTAssertEqual(sut.supportedInterfaceOrientations, UIViewController().supportedInterfaceOrientations)

        sut.hostViewController = hostViewController

        withExtendedLifetime(hostViewController) {
            XCTAssertEqual(sut.supportedInterfaceOrientations, .portrait)
            XCTAssertEqual(sut.preferredStatusBarStyle, .lightContent)
            XCTAssertTrue(sut.prefersStatusBarHidden)
            XCTAssertTrue(sut.prefersHomeIndicatorAutoHidden)
        }
    }

    @MainActor
    func testDropInViewControllerDoesNotPresentAfterDismissal() throws {
        let sut = try DropInViewController(dropInComponent: makeDropInComponent())
        sut.dismissDropIn(animated: false, completion: nil)

        sut.viewDidAppear(false)

        XCTAssertNil(sut.presentedViewController)
    }

    private func makeDropInConfigurationDTO() -> DropInConfigurationDTO {
        DropInConfigurationDTO(
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
    }

    @MainActor
    private func makeDropInComponent() throws -> DropInComponent {
        let dropInConfigurationDTO = makeDropInConfigurationDTO()
        let payment = Payment(amount: Amount(value: 1600, currencyCode: "USD"), countryCode: "US")
        return try DropInComponent(
            paymentMethods: PaymentMethods(regular: [], stored: []),
            context: dropInConfigurationDTO.createAdyenContext(payment: payment),
            configuration: dropInConfigurationDTO.createDropInConfiguration(payment: payment)
        )
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
    weak var hostViewController: UIViewController?
    /// Stubbed so the manager's "is anything presented?" check does not rely on a real UIKit transition.
    /// CI simulators do not reliably run presentation transitions to completion, which previously hung the tests.
    var stubbedPresentedViewController: UIViewController?
    private(set) var dismissDropInCallCount = 0
    private var pendingDismissalCompletion: (() -> Void)?

    override var presentedViewController: UIViewController? {
        stubbedPresentedViewController
    }

    func dismissDropIn(animated _: Bool, completion: (() -> Void)?) {
        dismissDropInCallCount += 1
        pendingDismissalCompletion = completion
    }

    /// Invokes the dismissal completion UIKit would have delivered.
    func completePendingDismissal() {
        stubbedPresentedViewController = nil
        let completion = pendingDismissalCompletion
        pendingDismissalCompletion = nil
        completion?()
    }
}

private class MockHostViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }
}
