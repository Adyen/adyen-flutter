@_spi(AdyenInternal) import Adyen
@testable import adyen_checkout
#if canImport(AdyenSession)
    import AdyenSession
#endif
import XCTest

final class SessionHolderTests: XCTestCase {
    func test_givenSessionIsInUse_whenResetting_thenKeepsSession() {
        let sessionHolder = SessionHolder()
        let sessionDelegate = SessionDelegateStub()
        sessionHolder.sessionDelegate = sessionDelegate
        sessionHolder.markSessionAsInUse()

        sessionHolder.reset()

        XCTAssertTrue(sessionHolder.sessionDelegate === sessionDelegate)
        XCTAssertTrue(sessionHolder.isSessionInUse)
    }

    func test_givenSessionIsReleased_whenResetting_thenClearsSession() {
        let sessionHolder = SessionHolder()
        sessionHolder.sessionDelegate = SessionDelegateStub()
        sessionHolder.markSessionAsInUse()
        sessionHolder.releaseSession()

        sessionHolder.reset()

        XCTAssertNil(sessionHolder.sessionDelegate)
        XCTAssertFalse(sessionHolder.isSessionInUse)
    }

    func test_givenSessionWasNeverUsed_whenResetting_thenClearsSession() {
        let sessionHolder = SessionHolder()
        sessionHolder.sessionDelegate = SessionDelegateStub()

        sessionHolder.reset()

        XCTAssertNil(sessionHolder.sessionDelegate)
    }
}

private final class SessionDelegateStub: AdyenSessionDelegate {
    func didComplete(with _: AdyenSessionResult, component _: Component, session _: AdyenSession) {}

    func didFail(with _: Error, from _: Component, session _: AdyenSession) {}

    func didOpenExternalApplication(component _: ActionComponent, session _: AdyenSession) {}
}
