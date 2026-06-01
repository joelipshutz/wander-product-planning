import XCTest
@testable import Wander

final class NavigationContractTests: XCTestCase {
    func testBottomNavigationHasFourProductTabsOnly() {
        XCTAssertEqual(WanderTab.allCases, [.map, .add, .discover, .profile])
    }
}
