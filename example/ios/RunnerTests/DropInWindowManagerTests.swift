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
        let windowPresenter = DropInWindowPresenterMock()
        let manager = DropInWindowManager(windowPresenter: windowPresenter)
        let dropInComponent = try makeDropInComponent()

        try manager.present(dropInViewController: dropInComponent.viewController)

        let dropInWindow = windowPresenter.window
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
        let windowPresenter = DropInWindowPresenterMock()
        let manager = DropInWindowManager(windowPresenter: windowPresenter)
        let dropInViewController = UIViewController()
        try manager.present(dropInViewController: dropInViewController)
        var completedDismissals = 0

        manager.dismiss(dropInViewController: dropInViewController, animated: false) { completedDismissals += 1 }
        manager.dismiss(dropInViewController: dropInViewController, animated: false) { completedDismissals += 1 }

        // The later request cannot replace the terminal completion that already owns the dismissal.
        XCTAssertEqual(windowPresenter.dismissCallCount, 1)
        XCTAssertEqual(completedDismissals, 0)

        windowPresenter.completePendingDismissal()

        XCTAssertEqual(completedDismissals, 1)
        XCTAssertTrue(hostWindow.isKeyWindow)
    }

    @MainActor
    func test_givenDropInIsPresented_whenSceneDisconnects_thenCleansUpAndReportsUnexpectedDismissal() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        // The scene disconnect path deliberately leaves the key window untouched, so restore it here to
        // keep the host application usable for the remaining tests.
        defer { hostWindow.makeKey() }
        let windowPresenter = DropInWindowPresenterMock()
        let manager = DropInWindowManager(windowPresenter: windowPresenter)
        let delegate = DropInWindowManagerDelegateMock()
        manager.delegate = delegate
        try manager.present(dropInViewController: UIViewController())

        windowPresenter.simulateSceneDisconnect()

        XCTAssertEqual(delegate.unexpectedDismissals, 1)
    }

    @MainActor
    func test_givenDismissalIsRequested_whenSceneDisconnects_thenCompletesDismissalOnce() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let windowPresenter = DropInWindowPresenterMock()
        let manager = DropInWindowManager(windowPresenter: windowPresenter)
        var completedDismissals = 0
        let delegate = DropInWindowManagerDelegateMock()
        manager.delegate = delegate
        let dropInViewController = UIViewController()
        try manager.present(dropInViewController: dropInViewController)
        // Dismissal is requested but never completed by UIKit, leaving the manager mid-dismissal.
        manager.dismiss(dropInViewController: dropInViewController, animated: false) { completedDismissals += 1 }

        windowPresenter.simulateSceneDisconnect()

        XCTAssertEqual(completedDismissals, 1)
        XCTAssertEqual(delegate.unexpectedDismissals, 0)

        windowPresenter.completePendingDismissal()

        XCTAssertEqual(completedDismissals, 1)
    }

    @MainActor
    func test_givenNewPresentationAfterSceneDisconnect_whenOldDismissalCompletes_thenKeepsNewPresentation() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let windowPresenter = DropInWindowPresenterMock()
        let manager = DropInWindowManager(windowPresenter: windowPresenter)
        let firstViewController = UIViewController()
        try manager.present(dropInViewController: firstViewController)
        manager.dismiss(dropInViewController: firstViewController, animated: false)
        windowPresenter.simulateSceneDisconnect()

        hostWindow.makeKey()
        let secondViewController = UIViewController()
        XCTAssertTrue(try manager.present(dropInViewController: secondViewController))

        windowPresenter.completePendingDismissal()

        XCTAssertFalse(try manager.present(dropInViewController: UIViewController()))
        manager.cleanUp()
    }

    @MainActor
    func test_givenSceneDisconnectDuringFinalization_whenFinalizationCompletes_thenReportsOneTerminalResult() throws {
        let hostWindow = try XCTUnwrap(activeWindow())
        defer { hostWindow.makeKey() }
        let windowPresenter = DropInWindowPresenterMock()
        let manager = DropInWindowManager(windowPresenter: windowPresenter)
        let dropInViewController = UIViewController()
        var completedDismissals = 0
        let delegate = DropInWindowManagerDelegateMock()
        manager.delegate = delegate
        try manager.present(dropInViewController: dropInViewController)
        let finishFinalization = {
            manager.dismiss(
                dropInViewController: dropInViewController,
                animated: false,
                completion: { completedDismissals += 1 }
            )
        }

        windowPresenter.simulateSceneDisconnect()
        finishFinalization()

        XCTAssertEqual(delegate.unexpectedDismissals + completedDismissals, 1)
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

private final class DropInWindowPresenterMock: DropInWindowPresenting {
    private(set) var window: UIWindow?
    private(set) var dismissCallCount = 0
    private(set) var pendingDismissalCompletion: (() -> Void)?
    private var sceneDisconnectHandler: (() -> Void)?

    func makeWindow(for windowScene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        return window
    }

    /// Captures the dismissal instead of running the UIKit transition, so tests decide when it completes.
    func dismiss(_: UIViewController, animated _: Bool, completion: @escaping () -> Void) {
        dismissCallCount += 1
        pendingDismissalCompletion = completion
    }

    func observeSceneDisconnect(of _: UIWindowScene, handler: @escaping () -> Void) {
        sceneDisconnectHandler = handler
    }

    func stopObservingSceneDisconnect() {
        sceneDisconnectHandler = nil
    }

    func completePendingDismissal() {
        let completion = pendingDismissalCompletion
        pendingDismissalCompletion = nil
        completion?()
    }

    func simulateSceneDisconnect() {
        sceneDisconnectHandler?()
    }
}

private final class DropInWindowManagerDelegateMock: DropInWindowManagerDelegate {
    private(set) var unexpectedDismissals = 0

    func dropInWindowDidDismissUnexpectedly() {
        unexpectedDismissals += 1
    }
}
