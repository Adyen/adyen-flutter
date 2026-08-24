@testable import adyen_checkout
import XCTest

final class SessionHolderTests: XCTestCase {
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
