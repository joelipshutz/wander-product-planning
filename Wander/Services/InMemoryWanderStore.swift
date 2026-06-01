import Foundation

@MainActor
final class InMemoryWanderStore: ObservableObject {
    @Published private(set) var currentUser: LocalProfile
    @Published private(set) var profiles: [LocalProfile]
    @Published private(set) var follows: [LocalFollow]
    @Published private(set) var blocks: [LocalBlock]
    @Published private(set) var places: [LocalPlace]
    @Published private(set) var userPlaces: [LocalUserPlace]
    @Published private(set) var sourceArtifacts: [LocalSourceArtifact] = []
    @Published private(set) var extractionJobs: [LocalExtractionJob] = []
    @Published private(set) var syncOperations: [SyncOperation] = []

    let contactProvider: FakeContactProvider
    private let visibilityPolicy = VisibilityPolicy()

    init(fixtures: WanderFixtures = .seed) {
        self.currentUser = fixtures.currentUser
        self.profiles = fixtures.profiles
        self.places = fixtures.places
        self.userPlaces = fixtures.userPlaces
        self.contactProvider = fixtures.contactProvider
        self.follows = [
            LocalFollow(id: "follow_joe_maya", followerUserID: fixtures.currentUser.id, followedUserID: "user_maya", source: .contacts),
            LocalFollow(id: "follow_ryan_joe", followerUserID: "user_ryan", followedUserID: fixtures.currentUser.id, source: .profile),
            LocalFollow(id: "follow_joe_ryan", followerUserID: fixtures.currentUser.id, followedUserID: "user_ryan", source: .profile)
        ]
        self.blocks = []
    }

    func place(for id: String) -> LocalPlace? {
        places.first { $0.id == id }
    }

    func profile(for id: String) -> LocalProfile? {
        profiles.first { $0.id == id }
    }

    func contactsMatchingAppUsers() -> [ContactMatch] {
        contactProvider.seededMatches.filter { match in
            guard let userID = match.userID else { return true }
            return !isBlockedBetweenCurrentUserAnd(userID)
        }
    }

    func followingProfiles() -> [LocalProfile] {
        let followedIDs = Set(follows.filter { $0.followerUserID == currentUser.id }.map(\.followedUserID))
        return profiles.filter { followedIDs.contains($0.id) && !isBlockedBetweenCurrentUserAnd($0.id) }
    }

    func followerProfiles() -> [LocalProfile] {
        let followerIDs = Set(follows.filter { $0.followedUserID == currentUser.id }.map(\.followerUserID))
        return profiles.filter { followerIDs.contains($0.id) && !isBlockedBetweenCurrentUserAnd($0.id) }
    }

    func blockedProfiles() -> [LocalProfile] {
        let blockedIDs = Set(blocks.filter { $0.blockerUserID == currentUser.id }.map(\.blockedUserID))
        return profiles.filter { blockedIDs.contains($0.id) }
    }

    func userPlaceCount(for status: PlaceStatus, userID: String? = nil) -> Int {
        userPlaces.filter {
            $0.status == status && (userID == nil || $0.userID == userID)
        }.count
    }

    func visiblePlaces(for filters: DiscoverFilters = DiscoverFilters(query: "")) -> [VisiblePlace] {
        userPlaces.compactMap { userPlace in
            guard let place = place(for: userPlace.placeID),
                  let owner = profile(for: userPlace.userID),
                  filters.categories.isEmpty || filters.categories.contains(place.category),
                  filters.statuses.isEmpty || filters.statuses.contains(userPlace.status)
            else {
                return nil
            }

            let relationship = relationshipToOwner(owner.id)
            let blocked = isBlockedBetweenCurrentUserAnd(owner.id)
            guard visibilityPolicy.canSeePlace(
                viewerID: currentUser.id,
                ownerID: owner.id,
                visibility: userPlace.visibility,
                relationship: relationship,
                isBlocked: blocked
            ) else {
                return nil
            }

            return VisiblePlace(id: userPlace.id, place: place, userPlace: userPlace, owner: owner)
        }
    }

    private func relationshipToOwner(_ ownerID: String) -> ViewerRelationship {
        guard ownerID != currentUser.id else { return .owner }
        let viewerFollowsOwner = follows.contains { $0.followerUserID == currentUser.id && $0.followedUserID == ownerID }
        let ownerFollowsViewer = follows.contains { $0.followerUserID == ownerID && $0.followedUserID == currentUser.id }

        if viewerFollowsOwner && ownerFollowsViewer {
            return .mutual
        }

        if viewerFollowsOwner {
            return .follower
        }

        return .nonFollower
    }

    private func isBlockedBetweenCurrentUserAnd(_ userID: String) -> Bool {
        blocks.contains {
            ($0.blockerUserID == currentUser.id && $0.blockedUserID == userID) ||
            ($0.blockerUserID == userID && $0.blockedUserID == currentUser.id)
        }
    }
}

extension InMemoryWanderStore: ProfileRepository {
    func currentProfile() async throws -> LocalProfile? {
        currentUser
    }

    func searchProfiles(handleQuery: String) async throws -> [LocalProfile] {
        let normalized = handleQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }
        return profiles.filter {
            !isBlockedBetweenCurrentUserAnd($0.id) &&
            $0.id != currentUser.id &&
            $0.handle.lowercased().contains(normalized)
        }
    }
}

extension InMemoryWanderStore: FollowRepository {
    func follow(userID: String) async throws {
        guard userID != currentUser.id, !isBlockedBetweenCurrentUserAnd(userID) else { return }
        guard !follows.contains(where: { $0.followerUserID == currentUser.id && $0.followedUserID == userID }) else { return }
        follows.append(LocalFollow(id: "follow_\(currentUser.id)_\(userID)", followerUserID: currentUser.id, followedUserID: userID, source: .profile))
    }

    func unfollow(userID: String) async throws {
        follows.removeAll { $0.followerUserID == currentUser.id && $0.followedUserID == userID }
    }

    func relationship(to userID: String) async throws -> ViewerRelationship {
        relationshipToOwner(userID)
    }
}

extension InMemoryWanderStore: BlockRepository {
    func block(userID: String) async throws {
        guard userID != currentUser.id else { return }
        follows.removeAll {
            ($0.followerUserID == currentUser.id && $0.followedUserID == userID) ||
            ($0.followerUserID == userID && $0.followedUserID == currentUser.id)
        }
        guard !blocks.contains(where: { $0.blockerUserID == currentUser.id && $0.blockedUserID == userID }) else { return }
        blocks.append(LocalBlock(id: "block_\(currentUser.id)_\(userID)", blockerUserID: currentUser.id, blockedUserID: userID))
    }

    func isBlocked(userID: String) async throws -> Bool {
        isBlockedBetweenCurrentUserAnd(userID)
    }
}

extension InMemoryWanderStore: PlaceRepository {
    func placesInCurrentViewport() async throws -> [LocalPlace] {
        places
    }
}

extension InMemoryWanderStore: UserPlaceRepository {
    func userPlaces(for userID: String) async throws -> [LocalUserPlace] {
        userPlaces.filter { $0.userID == userID }
    }

    func save(_ userPlace: LocalUserPlace) async throws {
        if let index = userPlaces.firstIndex(where: { $0.id == userPlace.id }) {
            userPlaces[index] = userPlace
        } else {
            userPlaces.append(userPlace)
        }
        syncOperations.append(SyncOperation(id: "sync_\(userPlace.id)_\(Date().timeIntervalSince1970)", entityName: "LocalUserPlace", entityID: userPlace.id, operation: "upsert"))
    }
}

extension InMemoryWanderStore: SourceArtifactRepository {
    func save(_ artifact: LocalSourceArtifact) async throws {
        sourceArtifacts.append(artifact)
    }
}

extension InMemoryWanderStore: ExtractionRepository {
    func job(for artifactID: String) async throws -> LocalExtractionJob? {
        extractionJobs.first { $0.sourceArtifactID == artifactID }
    }
}

extension InMemoryWanderStore: DiscoverRepository {
    func search(filters: DiscoverFilters) async throws -> [VisiblePlace] {
        visiblePlaces(for: filters)
    }
}
