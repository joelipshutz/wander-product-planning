import XCTest
@testable import Wander

final class LLMFilterParserTests: XCTestCase {
    func testParserMapsRawQueryToStructuredFilters() async throws {
        let parser = CheapFixtureFilterParser()
        let schema = DiscoverFilterSchema(
            allowedCategories: ["coffee", "hike", "restaurant"],
            allowedStatuses: [.been, .wannaGo]
        )

        let filters = try await parser.parse(query: "friend hikes I wanna do", schema: schema)

        XCTAssertEqual(filters.query, "friend hikes I wanna do")
        XCTAssertEqual(filters.categories, ["hike"])
        XCTAssertEqual(filters.statuses, [.wannaGo])
        XCTAssertEqual(filters.relationship, .mutual)
    }
}
