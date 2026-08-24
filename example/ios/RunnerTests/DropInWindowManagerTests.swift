import Adyen
@testable import adyen_checkout
#if canImport(AdyenDropIn)
    import AdyenDropIn
#endif
import UIKit
import XCTest

final class DropInWindowManagerTests: XCTestCase {
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

        try manager.present(dropInViewController: dropInComponent.viewController)

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
        try manager.present(dropInViewController: UIViewController())
        defer { manager.cleanUp() }

        let result = try manager.present(dropInViewController: UIViewController())

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
        let dropInViewController = UIViewController()
        try manager.present(dropInViewController: dropInViewController)
        var completedDismissals = 0

        manager.dismiss(viewController: dropInViewController, animated: false) { completedDismissals += 1 }
        manager.dismiss(viewController: dropInViewController, animated: false) { completedDismissals += 1 }

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
        try manager.present(dropInViewController: UIViewController())

        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)

        XCTAssertEqual(unexpectedDismissals, 1)
    }

    @MainActor
    func test_givenDismissalIsRequested_whenSceneDisconnects_thenCompletesDismissalOnce() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let notificationCenter = NotificationCenter()
        var pendingDismissalCompletion: (() -> Void)?
        let manager = DropInWindowManager(
            dismissViewController: { _, _, completion in
                pendingDismissalCompletion = completion
            },
            notificationCenter: notificationCenter
        )
        var completedDismissals = 0
        var unexpectedDismissals = 0
        manager.onUnexpectedDismissal = { unexpectedDismissals += 1 }
        let dropInViewController = UIViewController()
        try manager.present(dropInViewController: dropInViewController)
        // Dismissal is requested but never completed by UIKit, leaving the manager mid-dismissal.
        manager.dismiss(viewController: dropInViewController, animated: false) { completedDismissals += 1 }

        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)

        XCTAssertEqual(completedDismissals, 1)
        XCTAssertEqual(unexpectedDismissals, 0)

        pendingDismissalCompletion?()

        XCTAssertEqual(completedDismissals, 1)
    }

    @MainActor
    func test_givenNewPresentationAfterSceneDisconnect_whenOldDismissalCompletes_thenKeepsNewPresentation() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let notificationCenter = NotificationCenter()
        var pendingDismissalCompletion: (() -> Void)?
        let manager = DropInWindowManager(
            dismissViewController: { _, _, completion in
                pendingDismissalCompletion = completion
            },
            notificationCenter: notificationCenter
        )
        let firstViewController = UIViewController()
        try manager.present(dropInViewController: firstViewController)
        manager.dismiss(viewController: firstViewController, animated: false)
        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)

        hostWindow.makeKey()
        let secondViewController = UIViewController()
        XCTAssertTrue(try manager.present(dropInViewController: secondViewController))

        pendingDismissalCompletion?()

        XCTAssertFalse(try manager.present(dropInViewController: UIViewController()))
        manager.cleanUp()
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
        try manager.present(dropInViewController: dropInViewController)
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
        try manager.present(dropInViewController: UIViewController())
        newerWindow.makeKeyAndVisible()

        manager.cleanUp()

        XCTAssertTrue(newerWindow.isKeyWindow)
        XCTAssertFalse(hostWindow.isKeyWindow)
    }

    @MainActor
    func test_givenDropInIsPresented_whenCleanedUp_thenReportsWindowTeardown() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let manager = DropInWindowManager()
        var teardowns = 0
        manager.onWindowTornDown = { teardowns += 1 }
        try manager.present(dropInViewController: UIViewController())

        manager.cleanUp()

        XCTAssertEqual(teardowns, 1)
    }

    @MainActor
    func test_givenNoDropInIsPresented_whenCleanedUp_thenReportsNoWindowTeardown() {
        let manager = DropInWindowManager()
        var teardowns = 0
        manager.onWindowTornDown = { teardowns += 1 }

        manager.cleanUp()

        XCTAssertEqual(teardowns, 0)
    }

    @MainActor
    func test_givenDropInIsPresented_whenSceneDisconnects_thenReportsWindowTeardown() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let windowScene = try XCTUnwrap(hostWindow.windowScene)
        let notificationCenter = NotificationCenter()
        let manager = DropInWindowManager(notificationCenter: notificationCenter)
        var teardowns = 0
        manager.onWindowTornDown = { teardowns += 1 }
        try manager.present(dropInViewController: UIViewController())

        notificationCenter.post(name: UIScene.didDisconnectNotification, object: windowScene)

        XCTAssertEqual(teardowns, 1)
    }

    @MainActor
    func test_givenDismissalIsRequested_whenItCompletes_thenReportsTeardownBeforeCompletion() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        var pendingDismissalCompletion: (() -> Void)?
        let manager = DropInWindowManager(
            dismissViewController: { _, _, completion in
                pendingDismissalCompletion = completion
            }
        )
        var events: [String] = []
        manager.onWindowTornDown = { events.append("tornDown") }
        let dropInViewController = UIViewController()
        try manager.present(dropInViewController: dropInViewController)
        manager.dismiss(viewController: dropInViewController, animated: false) { events.append("completion") }

        pendingDismissalCompletion?()

        // The owner must be able to drop presentation-scoped state before the result reaches Flutter.
        XCTAssertEqual(events, ["tornDown", "completion"])
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
