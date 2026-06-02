import XCTest
@testable import Wander

@MainActor
final class WanderStoreTests: XCTestCase {
    private func makeStore() -> WanderStore {
        WanderStore(fixtures: WanderFixtures.seed())
    }

    func testSeededStoreShowsOwnAndVisibleSocialPlaces() {
        let store = makeStore()

        let names = Set(store.visiblePlaces().map { $0.place.canonicalName })

        XCTAssertTrue(names.contains("Woodcat Coffee"))
        XCTAssertTrue(names.contains("Griffith Observatory Trail"))
        XCTAssertTrue(names.contains("Larchmont Noodles"))
    }

    func testBlockRemovesFollowEdgesAndVisiblePlaces() {
        let store = makeStore()

        XCTAssertEqual(store.relationship(to: "user_ryan"), .mutual)
        XCTAssertTrue(store.visiblePlaces().contains { $0.owner.id == "user_ryan" })

        store.block(userID: "user_ryan")

        XCTAssertEqual(store.relationship(to: "user_ryan"), .nonFollower)
        XCTAssertFalse(store.visiblePlaces().contains { $0.owner.id == "user_ryan" })
        XCTAssertEqual(store.blockedProfiles().map(\.id), ["user_ryan"])
    }

    func testSavingSamePlaceMergesIntoExistingUserPlace() {
        let store = makeStore()
        let originalCount = store.currentUserVisiblePlaces.count

        let candidate = PlaceCandidate(
            id: "place_woodcat",
            name: "Woodcat Coffee",
            category: "coffee",
            latitude: 34.077,
            longitude: -118.260,
            confidence: 1
        )

        _ = store.saveCandidate(candidate, status: .wannaGo, visibility: .selfOnly, note: "updated", sourceType: .manual)

        XCTAssertEqual(store.currentUserVisiblePlaces.count, originalCount)
        let woodcat = store.currentUserVisiblePlaces.first { $0.place.canonicalName == "Woodcat Coffee" }
        XCTAssertEqual(woodcat?.userPlace.status, .wannaGo)
        XCTAssertEqual(woodcat?.userPlace.visibility, .selfOnly)
    }

    func testCurrentLocationSavePreservesSourceMetadata() {
        let store = makeStore()
        let candidate = store.currentLocationCandidates()[0]

        _ = store.saveCandidate(candidate, status: .been, visibility: .followers, note: nil, sourceType: .currentLocation)

        let saved = store.currentUserVisiblePlaces.first { $0.place.canonicalName == "Maru Coffee" }
        XCTAssertEqual(saved?.userPlace.sourceType, AddSourceType.currentLocation.rawValue)
        XCTAssertEqual(saved?.userPlace.nearbyConfirmed, true)
    }

    func testFollowersAndFollowingUseGraphEdges() {
        let store = makeStore()

        XCTAssertEqual(store.followers(of: store.currentUser.id).map(\.id), ["user_ryan"])
        XCTAssertEqual(store.following(of: store.currentUser.id).map(\.id), ["user_maya", "user_ryan"])

        store.block(userID: "user_ryan")

        XCTAssertTrue(store.followers(of: store.currentUser.id).isEmpty)
        XCTAssertEqual(store.following(of: store.currentUser.id).map(\.id), ["user_maya"])
    }

    func testLinkAndPhotoCreateUnresolvedDrafts() {
        let store = makeStore()

        let linkDraft = store.createUnresolvedDraft(sourceType: .link, originalInput: "https://example.com/place")
        let photoDraft = store.createUnresolvedDraft(sourceType: .photo)

        XCTAssertEqual(store.unresolvedDrafts, [linkDraft, photoDraft])
        XCTAssertEqual(linkDraft.sourceType, .link)
        XCTAssertEqual(photoDraft.sourceType, .photo)
    }

    func testUsernameSearchIsNearExactAndHidesBlockedUsers() {
        let store = makeStore()

        XCTAssertEqual(store.searchProfiles(handleQuery: "ry").map(\.handle), ["ryan"])

        store.block(userID: "user_ryan")

        XCTAssertTrue(store.searchProfiles(handleQuery: "ry").isEmpty)
        XCTAssertTrue(store.searchProfiles(handleQuery: "r").isEmpty)
    }

    func testContactMatchesOnlyIncludePeopleOnWander() async {
        let store = makeStore()

        let matches = await store.contactMatches()

        XCTAssertEqual(matches.map(\.id), ["contact_maya"])
        XCTAssertTrue(matches.allSatisfy { $0.isMatchedUser })
    }

    func testDiscoverSmartQueryUsesDeterministicParser() async {
        let store = makeStore()

        let results = await store.discover(query: "hikes in LA from people")

        XCTAssertEqual(results.places.map { $0.place.category }, ["hike"])
        XCTAssertTrue(results.profiles.isEmpty)
    }

    func testDiscoverCanScopeBetweenMyPlacesFriendsAndEveryone() async {
        let store = makeStore()

        let mine = await store.discover(query: "", scope: .myPlaces)
        let friends = await store.discover(query: "", scope: .friendsPlaces)
        let everyone = await store.discover(query: "", scope: .everyone)

        XCTAssertEqual(mine.places.map(\.owner.id), ["user_joe"])
        XCTAssertEqual(friends.places.map(\.owner.id), ["user_ryan"])
        XCTAssertEqual(Set(everyone.places.map(\.owner.id)), ["user_joe", "user_maya", "user_ryan"])
    }
}
