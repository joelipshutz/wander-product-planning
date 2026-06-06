import XCTest
@testable import Wander

@MainActor
final class WanderStoreTests: XCTestCase {
    private func makeStore() -> WanderStore {
        WanderStore(fixtures: WanderFixtures.seed())
    }

    func testEmptyFixturesStartWithoutDemoPeopleOrPlaces() {
        let store = WanderStore(fixtures: WanderFixtures.empty())

        XCTAssertEqual(store.currentUser.displayName, "You")
        XCTAssertTrue(store.visiblePlaces().isEmpty)
        XCTAssertEqual(store.following(of: store.currentUser.id), [])
        XCTAssertEqual(store.followers(of: store.currentUser.id), [])
    }

    func testSignedInSessionUpdatesCurrentProfileShell() {
        let store = WanderStore(fixtures: WanderFixtures.empty())

        store.apply(
            authState: .signedIn(
                AuthSession(
                    userID: "user_live",
                    displayName: nil,
                    handle: nil,
                    email: "jolipshutz@gmail.com"
                )
            )
        )

        XCTAssertEqual(store.currentUser.id, "user_live")
        XCTAssertEqual(store.currentUser.handle, "jolipshutz")
        XCTAssertEqual(store.currentUser.displayName, "jolipshutz@gmail.com")
        XCTAssertEqual(store.profiles.map(\.id), ["user_live"])
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
        let candidate = PlaceCandidate(
            id: "mapkit_maru_3404070_-11823540",
            name: "Maru Coffee",
            category: "coffee",
            address: "101 Arts District",
            locality: "Los Angeles",
            region: "CA",
            country: "US",
            latitude: 34.0407,
            longitude: -118.2354,
            sourceProvider: "mapkit",
            sourceProviderPlaceID: "mapkit_maru_3404070_-11823540",
            confidence: 0.92
        )

        _ = store.saveCandidate(candidate, status: .been, visibility: .followers, note: nil, sourceType: .currentLocation)

        let saved = store.currentUserVisiblePlaces.first { $0.place.canonicalName == "Maru Coffee" }
        XCTAssertEqual(saved?.userPlace.sourceType, AddSourceType.currentLocation.rawValue)
        XCTAssertEqual(saved?.userPlace.nearbyConfirmed, true)
        XCTAssertEqual(saved?.place.address, "101 Arts District")
        XCTAssertEqual(saved?.place.sourceProviderPlaceID, "mapkit_maru_3404070_-11823540")
    }

    func testCurrentLocationCandidatesUseInjectedResolver() async throws {
        let resolver = FakePlaceResolver(
            currentLocationCandidates: [
                PlaceCandidate(
                    id: "mapkit_here",
                    name: "Here Cafe",
                    category: "coffee",
                    latitude: 34.1,
                    longitude: -118.2,
                    sourceProviderPlaceID: "mapkit_here",
                    confidence: 0.9
                )
            ]
        )
        let store = WanderStore(fixtures: WanderFixtures.empty(), placeResolver: resolver)

        let candidates = try await store.currentLocationCandidates()

        XCTAssertEqual(candidates.map(\.name), ["Here Cafe"])
        XCTAssertEqual(resolver.currentLocationCallCount, 1)
    }

    func testManualCandidatesUseInjectedResolverInput() async throws {
        let resolver = FakePlaceResolver(
            manualCandidates: [
                PlaceCandidate(
                    id: "mapkit_larchmont",
                    name: "Larchmont Noodles",
                    category: "restaurant",
                    latitude: 34.073,
                    longitude: -118.323,
                    sourceProviderPlaceID: "mapkit_larchmont",
                    confidence: 0.88
                )
            ]
        )
        let store = WanderStore(fixtures: WanderFixtures.empty(), placeResolver: resolver)

        let candidates = try await store.manualCandidates(name: "Larchmont Noodles", areaHint: "LA", category: "restaurant")

        XCTAssertEqual(candidates.map(\.name), ["Larchmont Noodles"])
        XCTAssertEqual(resolver.manualInputs, [ManualPlaceInput(name: "Larchmont Noodles", areaHint: "LA", category: "restaurant")])
    }

    func testLinkCandidatesUseInjectedResolverInput() async throws {
        let resolver = FakePlaceResolver(
            linkCandidates: [
                PlaceCandidate(
                    id: "mapkit_link_place",
                    name: "Linked Place",
                    category: "restaurant",
                    latitude: 34.07,
                    longitude: -118.32,
                    sourceProviderPlaceID: "mapkit_link_place",
                    confidence: 0.86
                )
            ]
        )
        let store = WanderStore(fixtures: WanderFixtures.empty(), placeResolver: resolver)

        let candidates = try await store.linkCandidates("https://maps.google.com/?q=Linked+Place")

        XCTAssertEqual(candidates.map(\.name), ["Linked Place"])
        XCTAssertEqual(resolver.linkInputs, [LinkPlaceInput(rawValue: "https://maps.google.com/?q=Linked+Place")])
    }

    func testSaveCandidatePersistsQuestionAttributes() {
        let store = makeStore()
        let candidate = PlaceCandidate(
            id: "manual_answer_test",
            name: "Answer Test Coffee",
            category: "coffee",
            latitude: 34.0522,
            longitude: -118.2437,
            confidence: 0.8
        )

        let result = store.saveCandidate(
            candidate,
            status: .been,
            visibility: .followers,
            note: "has answers",
            sourceType: .manual,
            attributes: [
                PlaceAttributeDraft(questionKey: "rating_signal", valueType: "emoji_scale", stringValue: "great"),
                PlaceAttributeDraft(questionKey: "work_setup", valueType: "single_choice", stringValue: "yes"),
                PlaceAttributeDraft(questionKey: "coffee_tags", valueType: "multi_tag", stringValues: ["wifi solid", "quiet"])
            ]
        )

        let attributes = store.attributes(for: result.userPlaceID)
        XCTAssertEqual(attributes.map(\.questionKey), ["coffee_tags", "rating_signal", "work_setup"])
        XCTAssertEqual(attributes.first { $0.questionKey == "rating_signal" }?.valueJSON, "\"great\"")
        XCTAssertEqual(attributes.first { $0.questionKey == "coffee_tags" }?.valueJSON, "[\"wifi solid\",\"quiet\"]")
        XCTAssertEqual(store.currentUserVisiblePlaces.first { $0.id == result.userPlaceID }?.userPlace.ratingSignal, "great")
    }

    func testUpdatingCandidateReplacesQuestionAttributesWhenProvided() {
        let store = makeStore()
        let candidate = PlaceCandidate(
            id: "place_woodcat",
            name: "Woodcat Coffee",
            category: "coffee",
            latitude: 34.077,
            longitude: -118.260,
            confidence: 1
        )

        let result = store.saveCandidate(
            candidate,
            status: .been,
            visibility: .followers,
            note: "changed answers",
            sourceType: .manual,
            attributes: [
                PlaceAttributeDraft(questionKey: "rating_signal", valueType: "emoji_scale", stringValue: "good")
            ]
        )

        let attributes = store.attributes(for: result.userPlaceID)
        XCTAssertEqual(attributes.map(\.questionKey), ["rating_signal"])
        XCTAssertEqual(attributes[0].valueJSON, "\"good\"")
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

    func testDiscoverMergesRemoteProfileSearch() async {
        let store = makeStore()
        let profileRepository = FakeProfileRepository(
            shells: [
                ProfileShell(
                    id: "user_sofia",
                    handle: "sofia",
                    displayName: "Sofia Rivera",
                    avatarURL: nil,
                    bio: nil,
                    relationship: .nonFollower
                )
            ]
        )
        let backend = WanderBackend(profileRepository: profileRepository)

        let results = await store.discover(query: "@so", backend: backend)

        XCTAssertEqual(results.profiles.map(\.handle), ["sofia"])
        XCTAssertEqual(profileRepository.queries, ["so"])
        XCTAssertNotNil(store.profileState(for: "user_sofia"))
    }

    func testRemoteSocialSaveMarksLocalCopySynced() async {
        let store = makeStore()
        let socialSaveRepository = FakeSocialPlaceSaveRepository(result: SaveResult(userPlaceID: "up_remote_saved", syncState: .synced))
        let backend = WanderBackend(socialPlaceSaveRepository: socialSaveRepository)
        let placeID = "11111111-1111-4111-8111-111111111111"
        let sourceUserPlaceID = "22222222-2222-4222-8222-222222222222"
        let socialPlace = VisiblePlace(
            id: sourceUserPlaceID,
            place: LocalPlace(
                localID: "remote_place_griffith",
                serverID: placeID,
                canonicalName: "Remote Griffith",
                category: "hike",
                latitude: 34.119,
                longitude: -118.300,
                syncState: .synced
            ),
            userPlace: LocalUserPlace(
                localID: "remote_up_maya_griffith",
                serverID: sourceUserPlaceID,
                userID: "user_maya",
                placeID: placeID,
                status: .been,
                visibility: .followers,
                note: "server row",
                sourceType: "manual",
                syncState: .synced
            ),
            owner: LocalProfile(
                localID: "remote_profile_maya",
                serverID: "user_maya",
                handle: "maya",
                displayName: "Maya",
                syncState: .synced
            )
        )

        let result = await store.saveVisiblePlace(socialPlace, backend: backend)

        XCTAssertEqual(result, SaveResult(userPlaceID: "up_remote_saved", syncState: .synced))
        XCTAssertEqual(socialSaveRepository.requests, [FakeSocialPlaceSaveRepository.Request(placeID: placeID, sourceUserPlaceID: sourceUserPlaceID)])
        XCTAssertTrue(store.currentUserVisiblePlaces.contains { $0.userPlace.serverID == "up_remote_saved" && $0.userPlace.syncState == .synced })
    }

    func testSocialSaveDoesNotCallRemoteForFixtureIDs() async {
        let store = makeStore()
        let socialSaveRepository = FakeSocialPlaceSaveRepository(result: SaveResult(userPlaceID: "up_remote_saved", syncState: .synced))
        let backend = WanderBackend(socialPlaceSaveRepository: socialSaveRepository)
        let socialPlace = store.visiblePlaces().first { $0.owner.id == "user_maya" }!

        let result = await store.saveVisiblePlace(socialPlace, backend: backend)

        XCTAssertEqual(result.syncState, .pendingCreate)
        XCTAssertTrue(socialSaveRepository.requests.isEmpty)
    }

    func testRemoteOwnPlaceSaveMarksLocalRowsSynced() async {
        let store = WanderStore(fixtures: WanderFixtures.empty())
        store.apply(authState: .signedIn(AuthSession(userID: "user_live", displayName: "Joe", handle: "joe")))
        let userPlaceRepository = FakeUserPlaceRepository(result: SaveResult(userPlaceID: "up_remote_maru", syncState: .synced, placeID: "place_remote_maru"))
        let backend = WanderBackend(userPlaceRepository: userPlaceRepository)
        let candidate = PlaceCandidate(
            id: "mk_maru",
            name: "Maru Coffee",
            category: "coffee",
            latitude: 34.045,
            longitude: -118.235,
            confidence: 0.92
        )

        let result = await store.saveCandidate(
            candidate,
            status: .been,
            visibility: .followers,
            note: "window table",
            sourceType: .currentLocation,
            attributes: [
                PlaceAttributeDraft(questionKey: "rating_signal", valueType: "emoji_scale", stringValue: "great")
            ],
            backend: backend
        )

        XCTAssertEqual(result, SaveResult(userPlaceID: "up_remote_maru", syncState: .synced, placeID: "place_remote_maru"))
        XCTAssertEqual(userPlaceRepository.savedDrafts.count, 1)
        XCTAssertEqual(userPlaceRepository.savedDrafts[0].place.canonicalName, "Maru Coffee")
        XCTAssertEqual(userPlaceRepository.savedDrafts[0].attributes.map(\.questionKey), ["rating_signal"])

        let saved = store.currentUserVisiblePlaces.first { $0.place.canonicalName == "Maru Coffee" }
        XCTAssertEqual(saved?.place.serverID, "place_remote_maru")
        XCTAssertEqual(saved?.userPlace.serverID, "up_remote_maru")
        XCTAssertEqual(saved?.userPlace.placeID, "place_remote_maru")
        XCTAssertEqual(saved?.userPlace.syncState, .synced)
        XCTAssertEqual(store.attributes(for: "up_remote_maru").map(\.questionKey), ["rating_signal"])
    }

    func testRemoteOwnPlaceSaveFailureLeavesFailedLocalRows() async {
        let store = WanderStore(fixtures: WanderFixtures.empty())
        store.apply(authState: .signedIn(AuthSession(userID: "user_live", displayName: "Joe", handle: "joe")))
        let userPlaceRepository = FakeUserPlaceRepository(error: WanderRemoteError.invalidResponse("network down"))
        let backend = WanderBackend(userPlaceRepository: userPlaceRepository)
        let candidate = PlaceCandidate(
            id: "manual_taco",
            name: "Taco Table",
            category: "restaurant",
            latitude: 34.0522,
            longitude: -118.2437,
            confidence: 0.7
        )

        let result = await store.saveCandidate(
            candidate,
            status: .wannaGo,
            visibility: .mutuals,
            note: nil,
            sourceType: .manual,
            attributes: [],
            backend: backend
        )

        XCTAssertEqual(result.syncState, .failed)
        XCTAssertEqual(userPlaceRepository.savedDrafts.count, 1)

        let saved = store.currentUserVisiblePlaces.first { $0.place.canonicalName == "Taco Table" }
        XCTAssertEqual(saved?.userPlace.syncState, .failed)
        XCTAssertNotNil(saved?.userPlace.lastSyncError)
        XCTAssertNotNil(store.lastRemoteError)
    }

    func testRemoteFollowFailureLeavesFailedLocalFollow() async {
        let store = makeStore()
        let followRepository = FakeFollowRepository(error: WanderRemoteError.invalidResponse("network down"))
        let backend = WanderBackend(followRepository: followRepository)

        await store.follow(userID: "user_sofia", source: .username, backend: backend)

        let follow = store.follows.first { $0.followedUserID == "user_sofia" }
        XCTAssertEqual(follow?.syncStateRaw, SyncState.failed.rawValue)
        XCTAssertEqual(followRepository.followedUserIDs, ["user_sofia"])
        XCTAssertNotNil(follow?.lastSyncError)
    }

    func testRemoteUnfollowFailureKeepsFailedLocalFollow() async {
        let store = makeStore()
        let followRepository = FakeFollowRepository(error: WanderRemoteError.invalidResponse("network down"))
        let backend = WanderBackend(followRepository: followRepository)

        await store.unfollow(userID: "user_maya", backend: backend)

        let follow = store.follows.first { $0.followedUserID == "user_maya" }
        XCTAssertEqual(follow?.syncStateRaw, SyncState.failed.rawValue)
        XCTAssertEqual(followRepository.unfollowedUserIDs, ["user_maya"])
        XCTAssertNotNil(follow?.lastSyncError)
    }

    func testRemoteUnblockFailureKeepsFailedLocalBlock() async {
        let store = makeStore()
        store.block(userID: "user_maya")
        let blockRepository = FakeBlockRepository(error: WanderRemoteError.invalidResponse("network down"))
        let backend = WanderBackend(blockRepository: blockRepository)

        await store.unblock(userID: "user_maya", backend: backend)

        let block = store.blocks.first { $0.blockedUserID == "user_maya" }
        XCTAssertEqual(block?.syncStateRaw, SyncState.failed.rawValue)
        XCTAssertEqual(blockRepository.unblockedUserIDs, ["user_maya"])
        XCTAssertNotNil(block?.lastSyncError)
    }
}

@MainActor
private final class FakeProfileRepository: ProfileRepository {
    private let shells: [ProfileShell]
    private(set) var queries: [String] = []

    init(shells: [ProfileShell]) {
        self.shells = shells
    }

    func currentProfile() async throws -> LocalProfile? {
        nil
    }

    func profile(id: String) async throws -> ProfileViewState {
        throw WanderRemoteError.notImplemented("fake profile")
    }

    func searchProfiles(handleQuery: String) async throws -> [ProfileShell] {
        queries.append(handleQuery)
        return shells
    }
}

@MainActor
private final class FakeFollowRepository: FollowRepository {
    private let error: Error?
    private(set) var followedUserIDs: [String] = []
    private(set) var unfollowedUserIDs: [String] = []

    init(error: Error? = nil) {
        self.error = error
    }

    func follow(userID: String) async throws {
        followedUserIDs.append(userID)
        if let error {
            throw error
        }
    }

    func unfollow(userID: String) async throws {
        unfollowedUserIDs.append(userID)
        if let error {
            throw error
        }
    }

    func followers(userID: String) async throws -> [ProfileShell] {
        []
    }

    func following(userID: String) async throws -> [ProfileShell] {
        []
    }

    func relationship(to userID: String) async throws -> ViewerRelationship {
        .nonFollower
    }
}

@MainActor
private final class FakeBlockRepository: BlockRepository {
    private let error: Error?
    private(set) var blockedUserIDs: [String] = []
    private(set) var unblockedUserIDs: [String] = []

    init(error: Error? = nil) {
        self.error = error
    }

    func block(userID: String) async throws {
        blockedUserIDs.append(userID)
        if let error {
            throw error
        }
    }

    func unblock(userID: String) async throws {
        unblockedUserIDs.append(userID)
        if let error {
            throw error
        }
    }

    func blockedProfiles() async throws -> [ProfileShell] {
        []
    }

    func isBlocked(userID: String) async throws -> Bool {
        false
    }
}

@MainActor
private final class FakeSocialPlaceSaveRepository: SocialPlaceSaveRepository {
    struct Request: Equatable {
        let placeID: String
        let sourceUserPlaceID: String
    }

    private let result: SaveResult
    private(set) var requests: [Request] = []

    init(result: SaveResult) {
        self.result = result
    }

    func saveVisiblePlace(placeID: String, sourceUserPlaceID: String) async throws -> SaveResult {
        requests.append(Request(placeID: placeID, sourceUserPlaceID: sourceUserPlaceID))
        return result
    }
}

@MainActor
private final class FakeUserPlaceRepository: UserPlaceRepository {
    private let result: SaveResult?
    private let error: Error?
    private(set) var savedDrafts: [UserPlaceDraft] = []

    init(result: SaveResult? = nil, error: Error? = nil) {
        self.result = result
        self.error = error
    }

    func userPlaces(for userID: String, filters: PlaceFilters) async throws -> [VisiblePlace] {
        []
    }

    func save(_ draft: UserPlaceDraft) async throws -> SaveResult {
        savedDrafts.append(draft)
        if let error {
            throw error
        }
        return result ?? SaveResult(userPlaceID: "up_fake", syncState: .synced, placeID: "place_fake")
    }

    func updateVisibility(userPlaceID: String, visibility: PlaceVisibility) async throws {}

    func delete(userPlaceID: String) async throws {}
}

@MainActor
private final class FakePlaceResolver: PlaceCandidateResolving {
    private let currentLocationResult: Result<[PlaceCandidate], Error>
    private let manualResult: Result<[PlaceCandidate], Error>
    private let linkResult: Result<[PlaceCandidate], Error>
    private(set) var currentLocationCallCount = 0
    private(set) var manualInputs: [ManualPlaceInput] = []
    private(set) var linkInputs: [LinkPlaceInput] = []

    init(
        currentLocationCandidates: [PlaceCandidate] = [],
        manualCandidates: [PlaceCandidate] = [],
        linkCandidates: [PlaceCandidate] = [],
        currentLocationError: Error? = nil,
        manualError: Error? = nil,
        linkError: Error? = nil
    ) {
        if let currentLocationError {
            self.currentLocationResult = .failure(currentLocationError)
        } else {
            self.currentLocationResult = .success(currentLocationCandidates)
        }

        if let manualError {
            self.manualResult = .failure(manualError)
        } else {
            self.manualResult = .success(manualCandidates)
        }

        if let linkError {
            self.linkResult = .failure(linkError)
        } else {
            self.linkResult = .success(linkCandidates)
        }
    }

    func resolveCurrentLocation() async throws -> [PlaceCandidate] {
        currentLocationCallCount += 1
        return try currentLocationResult.get()
    }

    func resolveManualEntry(_ input: ManualPlaceInput) async throws -> [PlaceCandidate] {
        manualInputs.append(input)
        return try manualResult.get()
    }

    func resolveLink(_ input: LinkPlaceInput) async throws -> [PlaceCandidate] {
        linkInputs.append(input)
        return try linkResult.get()
    }
}
