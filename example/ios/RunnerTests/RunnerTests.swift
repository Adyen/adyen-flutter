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
    private let testClientKey = "test_qwertyuiopasdfghjklzxcvbnmqwerty"

    func test_givenDropInConfigurationDTO_whenMapping_thenCreatesNativeSDKModels() {
        do {
            let dropInConfigurationDTO = createDropInConfigurationDTO()

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

    @MainActor
    func test_givenDropInIsPresented_whenCleanedUp_thenTearsDownDropInWindow() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        var dropInWindow: UIWindow?
        let manager = DropInWindowManager(
            windowFactory: {
                let window = UIWindow(windowScene: $0)
                dropInWindow = window
                return window
            }
        )
        let dropInComponent = try makeDropInComponent()

        try manager.present(viewController: dropInComponent.viewController)

        XCTAssertEqual(dropInWindow?.windowLevel.rawValue, UIWindow.Level.normal.rawValue + 1)
        XCTAssertTrue(dropInWindow?.isKeyWindow == true)
        XCTAssertFalse(dropInWindow?.rootViewController === dropInComponent.viewController)
        XCTAssertTrue(dropInWindow?.rootViewController?.presentedViewController === dropInComponent.viewController)

        manager.cleanUp()

        XCTAssertTrue(hostWindow.isKeyWindow)
        XCTAssertTrue(dropInWindow?.isHidden == true)
    }

    @MainActor
    func test_givenDropInIsPresented_whenPresentingAgain_thenKeepsExistingPresentation() throws {
        let manager = DropInWindowManager()
        try manager.present(viewController: UIViewController())
        defer { manager.cleanUp() }

        let result = try manager.present(viewController: UIViewController())

        XCTAssertFalse(result)
    }

    @MainActor
    func test_givenDropInIsPresented_whenMultipleDismissalsAreRequested_thenCompletesOnlyFirst() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        var dismissCallCount = 0
        var pendingDismissalCompletion: (() -> Void)?
        let manager = DropInWindowManager(
            dismissViewController: { _, _, completion in
                dismissCallCount += 1
                pendingDismissalCompletion = completion
            }
        )
        try manager.present(viewController: UIViewController())
        var completedDismissals = 0

        manager.dismiss(animated: false) { completedDismissals += 1 }
        manager.dismiss(animated: false) { completedDismissals += 1 }

        // The later request cannot replace the terminal completion that already owns the dismissal.
        XCTAssertEqual(dismissCallCount, 1)
        XCTAssertEqual(completedDismissals, 0)

        pendingDismissalCompletion?()

        XCTAssertEqual(completedDismissals, 1)
        XCTAssertTrue(hostWindow.isKeyWindow)
    }

    @MainActor
    func test_givenDropInIsPresented_whenSceneDisconnects_thenCleansUpAndReportsUnexpectedDismissal() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        // The scene disconnect path deliberately leaves the key window untouched, so restore it here to
        // keep the host application usable for the remaining tests.
        defer { hostWindow.makeKey() }
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let notificationCenter = NotificationCenter()
        let manager = DropInWindowManager(
            notificationCenter: notificationCenter
        )
        var unexpectedDismissals = 0
        manager.onUnexpectedDismissal = { unexpectedDismissals += 1 }
        try manager.present(viewController: UIViewController())

        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)

        XCTAssertEqual(unexpectedDismissals, 1)
    }

    @MainActor
    func test_givenDismissalIsRequested_whenSceneDisconnects_thenDoesNotReportUnexpectedDismissal() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let notificationCenter = NotificationCenter()
        let manager = DropInWindowManager(
            dismissViewController: { _, _, _ in },
            notificationCenter: notificationCenter
        )
        var unexpectedDismissals = 0
        manager.onUnexpectedDismissal = { unexpectedDismissals += 1 }
        try manager.present(viewController: UIViewController())
        // Dismissal is requested but never completed by UIKit, leaving the manager mid-dismissal.
        manager.dismiss(animated: false)

        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)

        XCTAssertEqual(unexpectedDismissals, 0)
    }

    @MainActor
    func test_givenSceneDisconnectDuringFinalization_whenFinalizationCompletes_thenReportsOneTerminalResult() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let notificationCenter = NotificationCenter()
        let manager = DropInWindowManager(
            notificationCenter: notificationCenter
        )
        let dropInViewController = UIViewController()
        var terminalResults = 0
        manager.onUnexpectedDismissal = { terminalResults += 1 }
        try manager.present(viewController: dropInViewController)
        let finishFinalization = {
            manager.dismiss(
                viewController: dropInViewController,
                animated: false,
                completion: { terminalResults += 1 }
            )
        }

        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)
        finishFinalization()

        XCTAssertEqual(terminalResults, 1)
    }

    @MainActor
    func test_givenNewerWindowIsKey_whenDropInIsDismissed_thenPreservesNewerKeyWindow() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let manager = DropInWindowManager()
        let newerWindow = UIWindow(windowScene: windowScene)
        newerWindow.rootViewController = UIViewController()
        defer {
            manager.cleanUp()
            newerWindow.isHidden = true
            hostWindow.makeKey()
        }
        try manager.present(viewController: UIViewController())
        newerWindow.makeKeyAndVisible()

        manager.cleanUp()

        XCTAssertTrue(newerWindow.isKeyWindow)
        XCTAssertFalse(hostWindow.isKeyWindow)
    }

    private func createDropInConfigurationDTO() -> DropInConfigurationDTO {
        DropInConfigurationDTO(
            environment: Environment.test,
            clientKey: testClientKey,
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
        let dropInConfigurationDTO = createDropInConfigurationDTO()
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

extension RunnerTests {
    func test_reset_whenSessionIsInUse_shouldDoNothing() {
        let sessionHolder = SessionHolder()
        sessionHolder.markSessionAsInUse()

        sessionHolder.reset()

        XCTAssertTrue(sessionHolder.isSessionInUse)
    }

    func test_reset_afterSessionIsReleased_shouldSucceed() {
        let sessionHolder = SessionHolder()
        sessionHolder.markSessionAsInUse()
        sessionHolder.releaseSession()

        sessionHolder.reset()

        XCTAssertFalse(sessionHolder.isSessionInUse)
    }
}
