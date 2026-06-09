import MapKit
import XCTest
@testable import Wander

final class WanderPlaceCategoryTests: XCTestCase {
    func testMapKitParksStayParks() {
        XCTAssertEqual(WanderPlaceCategory.primary(for: .park), "park")
        XCTAssertEqual(WanderPlaceCategory.primary(for: .nationalPark), "park")
    }

    func testCategorySymbolsIncludePark() {
        XCTAssertEqual(WanderPlaceCategory.symbolName(for: "park"), "tree.fill")
        XCTAssertEqual(WanderPlaceCategory.symbolName(for: "hike"), "figure.hiking")
    }
}
