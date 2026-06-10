import CoreGraphics
import XCTest
@testable import Wander

final class MapHitTestingTests: XCTestCase {
    func testScreenPointNearMarkerUsesPixelDistance() {
        let marker = CGPoint(x: 120, y: 240)

        XCTAssertTrue(
            MapHitTesting.isScreenPoint(
                CGPoint(x: 146, y: 260),
                nearAny: [marker]
            )
        )
    }

    func testScreenPointAwayFromMarkerClearsSelection() {
        let marker = CGPoint(x: 120, y: 240)

        XCTAssertFalse(
            MapHitTesting.isScreenPoint(
                CGPoint(x: 190, y: 260),
                nearAny: [marker]
            )
        )
    }
}
