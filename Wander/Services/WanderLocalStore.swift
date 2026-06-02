import Foundation

struct UnresolvedDraft: Identifiable, Equatable {
    let id: String
    let sourceType: AddSourceType
    let title: String
    let message: String
    let createdAt: Date
}

struct AuthGateCopy: Equatable {
    let title: String
    let message: String
    let primaryAction: String
    let secondaryAction: String?
}

struct ProfileStats: Equatable {
    let been: Int
    let wanna: Int
    let friends: Int
}

struct SmartFilter: Identifiable, Equatable {
    let id: String
    let title: String
    let query: String
}

@MainActor
final class WanderStore: ObservableObject {
    @Published private(set) var currentUser: LocalProfile
    @Published private(set) var profiles: [LocalProfile]
    @Published private(set) var places: [LocalPlace]
    @Published private(set) var userPlaces: [LocalUserPlace]
    @Published private(set) var follows: [LocalFollow]
    @Published private(set) var blocks: [LocalBlock]
    @Published private(set) var unresolvedDrafts: [UnresolvedDraft] = []
    @Published var defaultVisibility: PlaceVisibility

    let contactProvider: FakeContactProvider

    private let visibilityPolicy = VisibilityPolicy()
    private let parser = DeterministicFilterParser()

    let smartFilters: [SmartFilter] = [
        SmartFilter(id: "hikes-la", title: "hikes in LA", query: "hikes in LA"),
        SmartFilter(id: "coffee-work", title: "coffee to work from", query: "coffee work friendly"),
        SmartFilter(id: "patio-bars", title: "patio bars", query: "bars patio"),
        SmartFilter(id: "friends-liked", title: "friends liked", query: "friends been")
    ]

    init(fixtures: WanderFixtures) {
        self.currentUser = fixtures.currentUser
        self.profiles = fixtures.profiles
        self.places = fixtures.places
        self.userPlaces = fixtures.userPlaces
        self.follows = fixtures.follows
        self.blocks = fixtures.blocks
        self.contactProvider = fixtures.contactProvider
        self.defaultVisibility = fixtures.currentUser.defaultVisibility
    }

    var stats: ProfileStats {
        let mine = userPlaces.filter { $0.userID == currentUser.id && $0.deletedAt == nil }
        return ProfileStats(
            been: mine.filter { $0.status == .been }.count,
            wanna: mine.filter { $0.status == .wannaGo }.count,
            friends: profiles.filter { relationship(to: $0.id) == .mutual }.count
        )
    }

    var pendingSyncCount: Int {
        userPlaces.filter { $0.syncState != .synced }.count + unresolvedDrafts.count
    }

    var currentUserVisiblePlaces: [VisiblePlace] {
        visiblePlaces(filters: PlaceFilters(ownerScopes: ["you"]))
    }

    func visiblePlaces(filters: PlaceFilters = PlaceFilters()) -> [VisiblePlace] {
        userPlaces.compactMap { userPlace -> VisiblePlace? in
            guard userPlace.deletedAt == nil,
                  let place = places.first(where: { $0.id == userPlace.placeID }),
                  let owner = profiles.first(where: { $0.id == userPlace.userID })
            else { return nil }

            let relationship = relationship(to: owner.id)
            let blocked = isBlockedBetweenCurrentUser(and: owner.id)
            guard visibilityPolicy.canSeePlace(
                viewerID: currentUser.id,
                ownerID: owner.id,
                visibility: userPlace.visibility,
                relationship: relationship,
                isBlocked: blocked
            ) else { return nil }

            guard filters.statuses.isEmpty || filters.statuses.contains(userPlace.status) else { return nil }
            guard filters.categories.isEmpty || filters.categories.contains(place.category) else { return nil }

            if !filters.ownerScopes.isEmpty {
                let isMine = owner.id == currentUser.id
                let isFriend = relationship == .mutual
                let isFollowing = relationship == .follower || relationship == .mutual
                let allowed = (filters.ownerScopes.contains("you") && isMine)
                    || (filters.ownerScopes.contains("friends") && isFriend)
                    || (filters.ownerScopes.contains("following") && isFollowing && !isMine)
                    || (filters.ownerScopes.contains("social") && !isMine)
                guard allowed else { return nil }
            }

            return VisiblePlace(id: userPlace.id, place: place, userPlace: userPlace, owner: owner)
        }
    }

    func visiblePlaces(for profileID: String) -> [VisiblePlace] {
        visiblePlaces().filter { $0.owner.id == profileID }
    }

    func followers(of userID: String) -> [LocalProfile] {
        follows
            .filter { $0.followedUserID == userID }
            .compactMap { follow in profiles.first { $0.id == follow.followerUserID } }
            .filter { !isBlockedBetweenCurrentUser(and: $0.id) }
            .sorted { $0.handle < $1.handle }
    }

    func following(of userID: String) -> [LocalProfile] {
        follows
            .filter { $0.followerUserID == userID }
            .compactMap { follow in profiles.first { $0.id == follow.followedUserID } }
            .filter { !isBlockedBetweenCurrentUser(and: $0.id) }
            .sorted { $0.handle < $1.handle }
    }

    func relationship(to userID: String) -> ViewerRelationship {
        if userID == currentUser.id { return .owner }
        guard !isBlockedBetweenCurrentUser(and: userID) else { return .nonFollower }

        let iFollowThem = follows.contains { $0.followerUserID == currentUser.id && $0.followedUserID == userID }
        let theyFollowMe = follows.contains { $0.followerUserID == userID && $0.followedUserID == currentUser.id }

        if iFollowThem && theyFollowMe { return .mutual }
        if iFollowThem { return .follower }
        return .nonFollower
    }

    func shell(for profile: LocalProfile) -> ProfileShell {
        ProfileShell(
            id: profile.id,
            handle: profile.handle,
            displayName: profile.displayName,
            avatarURL: profile.avatarURL,
            bio: profile.bio,
            relationship: relationship(to: profile.id)
        )
    }

    func profileState(for profileID: String) -> ProfileViewState? {
        guard let profile = profiles.first(where: { $0.id == profileID }) else { return nil }
        let blocked = isBlockedBetweenCurrentUser(and: profile.id)
        return ProfileViewState(
            shell: shell(for: profile),
            visiblePlaces: blocked ? [] : visiblePlaces(for: profile.id),
            canFollow: profile.id != currentUser.id && !blocked && relationship(to: profile.id) == .nonFollower,
            canBlock: profile.id != currentUser.id,
            isBlocked: blocked
        )
    }

    func searchProfiles(handleQuery: String) -> [ProfileShell] {
        let normalized = handleQuery
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalized.count >= 2 else { return [] }

        return profiles
            .filter { profile in
                profile.id != currentUser.id
                    && !isBlockedBetweenCurrentUser(and: profile.id)
                    && (profile.searchHandle == normalized || profile.searchHandle.hasPrefix(normalized))
            }
            .map(shell(for:))
    }

    func contactMatches() async -> [ContactMatch] {
        let matches = (try? await contactProvider.matches()) ?? []
        return matches.filter { match in
            guard let userID = match.userID else { return false }
            return !isBlockedBetweenCurrentUser(and: userID)
        }
    }

    func parseDiscover(query: String) async -> DiscoverFilters {
        let schema = DiscoverFilterSchema(
            allowedCategories: Array(Set(places.map(\.category))).sorted(),
            allowedStatuses: PlaceStatus.allCases,
            allowedRelationships: [.follower, .mutual]
        )
        return (try? await parser.parse(query: query, schema: schema)) ?? DiscoverFilters(query: query)
    }

    func discover(query: String, scope: DiscoverPlaceScope = .friendsPlaces) async -> DiscoverResults {
        let filters = await parseDiscover(query: query)
        var placeFilters = PlaceFilters()
        placeFilters.statuses = filters.statuses
        placeFilters.categories = filters.categories

        if scope == .myPlaces {
            placeFilters.ownerScopes = scope.ownerScopes
        } else if let relationship = filters.relationship {
            switch relationship {
            case .mutual:
                placeFilters.ownerScopes = ["friends"]
            case .follower:
                placeFilters.ownerScopes = ["following"]
            case .owner:
                placeFilters.ownerScopes = ["you"]
            case .nonFollower:
                placeFilters.ownerScopes = []
            }
        } else if query.isEmpty {
            placeFilters.ownerScopes = scope.ownerScopes
        }

        let places = visiblePlaces(filters: placeFilters)
        let profiles = searchProfiles(handleQuery: query)
        return DiscoverResults(places: places, profiles: profiles)
    }

    func currentLocationCandidates() -> [PlaceCandidate] {
        [
            PlaceCandidate(
                id: "candidate_maru",
                name: "Maru Coffee",
                category: "coffee",
                latitude: 34.0407,
                longitude: -118.2354,
                confidence: 0.92
            )
        ]
    }

    func manualCandidates(name: String, areaHint: String?, category: String?) -> [PlaceCandidate] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return [
            PlaceCandidate(
                id: "manual_\(slug(trimmed))",
                name: trimmed,
                category: category?.isEmpty == false ? category ?? "place" : "place",
                latitude: 34.0522,
                longitude: -118.2437,
                confidence: areaHint?.isEmpty == false ? 0.72 : 0.48
            )
        ]
    }

    @discardableResult
    func saveCandidate(
        _ candidate: PlaceCandidate,
        status: PlaceStatus,
        visibility: PlaceVisibility,
        note: String?,
        sourceType: AddSourceType
    ) -> SaveResult {
        let place = upsertPlace(from: candidate, sourceType: sourceType)

        if let existing = userPlaces.first(where: { $0.userID == currentUser.id && $0.placeID == place.id && $0.deletedAt == nil }) {
            existing.statusRaw = status.rawValue
            existing.visibilityRaw = visibility.rawValue
            existing.note = note
            existing.updatedAt = .now
            existing.localUpdatedAt = .now
            existing.syncStateRaw = SyncState.pendingUpdate.rawValue
            objectWillChange.send()
            return SaveResult(userPlaceID: existing.id, syncState: existing.syncState)
        }

        let userPlace = LocalUserPlace(
            localID: "local_up_\(currentUser.handle)_\(slug(place.canonicalName))",
            userID: currentUser.id,
            placeID: place.id,
            status: status,
            visibility: visibility,
            note: note,
            nearbyConfirmed: sourceType == .currentLocation,
            sourceType: sourceType.rawValue,
            syncState: .pendingCreate
        )
        userPlaces.append(userPlace)
        return SaveResult(userPlaceID: userPlace.id, syncState: userPlace.syncState)
    }

    @discardableResult
    func createUnresolvedDraft(sourceType: AddSourceType, originalInput: String? = nil) -> UnresolvedDraft {
        let title: String
        let message: String

        switch sourceType {
        case .link:
            title = "This link needs a little help."
            message = originalInput?.isEmpty == false ? originalInput ?? "Saved as a draft." : "Saved as a draft until backend extraction is connected."
        case .photo:
            title = "Photo saved as a draft."
            message = "Photo extraction waits for the backend job lane."
        default:
            title = "Draft saved."
            message = "You can finish this manually."
        }

        let draft = UnresolvedDraft(
            id: "draft_\(sourceType.rawValue)_\(unresolvedDrafts.count + 1)",
            sourceType: sourceType,
            title: title,
            message: message,
            createdAt: .now
        )
        unresolvedDrafts.append(draft)
        return draft
    }

    func saveVisiblePlace(_ visiblePlace: VisiblePlace, status: PlaceStatus = .wannaGo) -> SaveResult {
        saveCandidate(
            PlaceCandidate(
                id: visiblePlace.place.id,
                name: visiblePlace.place.canonicalName,
                category: visiblePlace.place.category,
                latitude: visiblePlace.place.latitude,
                longitude: visiblePlace.place.longitude,
                confidence: visiblePlace.place.confidence ?? 1
            ),
            status: status,
            visibility: defaultVisibility,
            note: visiblePlace.userPlace.note,
            sourceType: .socialSave
        )
    }

    func follow(userID: String, source: FollowSource = .profile) {
        guard userID != currentUser.id,
              !isBlockedBetweenCurrentUser(and: userID),
              !follows.contains(where: { $0.followerUserID == currentUser.id && $0.followedUserID == userID })
        else { return }

        follows.append(
            LocalFollow(
                localID: "local_follow_\(currentUser.id)_\(userID)",
                followerUserID: currentUser.id,
                followedUserID: userID,
                source: source,
                syncState: .pendingCreate
            )
        )
    }

    func unfollow(userID: String) {
        follows.removeAll { $0.followerUserID == currentUser.id && $0.followedUserID == userID }
    }

    func block(userID: String) {
        guard userID != currentUser.id,
              !blocks.contains(where: { $0.blockerUserID == currentUser.id && $0.blockedUserID == userID })
        else { return }

        follows.removeAll { follow in
            (follow.followerUserID == currentUser.id && follow.followedUserID == userID)
                || (follow.followerUserID == userID && follow.followedUserID == currentUser.id)
        }
        blocks.append(
            LocalBlock(
                localID: "local_block_\(currentUser.id)_\(userID)",
                blockerUserID: currentUser.id,
                blockedUserID: userID,
                syncState: .pendingCreate
            )
        )
    }

    func unblock(userID: String) {
        blocks.removeAll { $0.blockerUserID == currentUser.id && $0.blockedUserID == userID }
    }

    func blockedProfiles() -> [ProfileShell] {
        blocks
            .filter { $0.blockerUserID == currentUser.id }
            .compactMap { block in profiles.first(where: { $0.id == block.blockedUserID }) }
            .map(shell(for:))
    }

    func authGate(for action: AddSourceType) -> AuthGateCopy {
        switch action {
        case .socialSave:
            AuthGateCopy(title: "Sign in to save from people", message: "Social saves sync to your map after you have an account.", primaryAction: "Sign in", secondaryAction: "Keep browsing")
        default:
            AuthGateCopy(title: "Sign in to sync this place", message: "Keep it on this phone for now, or sign in to back it up.", primaryAction: "Sign in", secondaryAction: "Keep it on this phone")
        }
    }

    private func isBlockedBetweenCurrentUser(and userID: String) -> Bool {
        blocks.contains { block in
            (block.blockerUserID == currentUser.id && block.blockedUserID == userID)
                || (block.blockerUserID == userID && block.blockedUserID == currentUser.id)
        }
    }

    private func upsertPlace(from candidate: PlaceCandidate, sourceType: AddSourceType) -> LocalPlace {
        if let existing = places.first(where: { $0.id == candidate.id || $0.canonicalName.caseInsensitiveCompare(candidate.name) == .orderedSame }) {
            return existing
        }

        let place = LocalPlace(
            localID: "local_place_\(slug(candidate.name))",
            canonicalName: candidate.name,
            category: candidate.category,
            locality: "Los Angeles",
            region: "CA",
            latitude: candidate.latitude ?? 34.0522,
            longitude: candidate.longitude ?? -118.2437,
            sourceProvider: sourceType == .manual ? "manual" : "mapkit",
            sourceProviderPlaceID: candidate.id,
            confidence: candidate.confidence,
            syncState: .pendingCreate
        )
        places.append(place)
        return place
    }

    private func slug(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }
}
