import XCTest
@testable import Wander

final class DiscoverParserTests: XCTestCase {
    func testDeterministicParserMapsQueryToAllowedFiltersOnly() async throws {
        let parser = DeterministicFilterParser()
        let schema = DiscoverFilterSchema(
            allowedCategories: ["coffee", "hike", "restaurant"],
            allowedStatuses: [.been, .wannaGo],
            allowedRelationships: [.follower, .mutual]
        )

        let filters = try await parser.parse(query: "been hikes in LA from friends", schema: schema)

        XCTAssertEqual(filters.categories, ["hike"])
        XCTAssertEqual(filters.statuses, [.been])
        XCTAssertEqual(filters.relationship, .mutual)
        XCTAssertEqual(filters.area, "LA")
    }
}
