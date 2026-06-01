import XCTest
@testable import Wander

@MainActor
final class InMemoryWanderStoreTests: XCTestCase {
    func testFollowThenBlockRemovesFollowEdgesAndHidesUser() async throws {
        let store = InMemoryWanderStore()

        try await store.follow(userID: "user_maya")
        let followedRelationship = try await store.relationship(to: "user_maya")
        XCTAssertEqual(followedRelationship, .follower)

        try await store.block(userID: "user_maya")

        let isBlocked = try await store.isBlocked(userID: "user_maya")
        let blockedRelationship = try await store.relationship(to: "user_maya")
        XCTAssertTrue(isBlocked)
        XCTAssertEqual(blockedRelationship, .nonFollower)
        let searchResults = try await store.searchProfiles(handleQuery: "maya")
        XCTAssertTrue(searchResults.isEmpty)
    }

    func testSaveAddsOrUpdatesUserPlaceAndEnqueuesSyncOperation() async throws {
        let store = InMemoryWanderStore()
        let userPlace = LocalUserPlace(
            id: "up_test",
            userID: store.currentUser.id,
            placeID: "place_woodcat",
            status: .wannaGo,
            visibility: .selfOnly,
            sourceType: "manual",
            syncState: .pendingCreate
        )

        try await store.save(userPlace)

        let saved = try await store.userPlaces(for: store.currentUser.id)
        XCTAssertTrue(saved.contains { $0.id == "up_test" })
        XCTAssertEqual(store.syncOperations.count, 1)
        XCTAssertEqual(store.syncOperations.first?.entityID, "up_test")
    }

    func testVisiblePlacesExcludeSelfAndBlockedRowsForSocialViewer() async throws {
        let store = InMemoryWanderStore()

        XCTAssertTrue(store.visiblePlaces().contains { $0.owner.id == "user_maya" })

        try await store.block(userID: "user_maya")

        XCTAssertFalse(store.visiblePlaces().contains { $0.owner.id == "user_maya" })
    }
}
