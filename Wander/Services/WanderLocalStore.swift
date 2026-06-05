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
    @Published private(set) var placeAttributes: [LocalPlaceAttribute]
    @Published private(set) var follows: [LocalFollow]
    @Published private(set) var blocks: [LocalBlock]
    @Published private(set) var unresolvedDrafts: [UnresolvedDraft] = []
    @Published private(set) var remoteVisiblePlaceCache: [VisiblePlace] = []
    @Published private(set) var lastRemoteError: String?
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
        self.placeAttributes = fixtures.placeAttributes
        self.follows = fixtures.follows
        self.blocks = fixtures.blocks
        self.contactProvider = fixtures.contactProvider
        self.defaultVisibility = fixtures.currentUser.defaultVisibility
    }

    func apply(authState: AuthState) {
        switch authState {
        case .signedIn(let session):
            apply(session: session)
        case .signedOut, .unavailable:
            applySignedOutProfile()
        case .loading:
            break
        }
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
        userPlaces.filter { $0.syncState != .synced }.count
            + placeAttributes.filter { $0.syncState != .synced }.count
            + unresolvedDrafts.count
    }

    var currentUserVisiblePlaces: [VisiblePlace] {
        visiblePlaces(filters: PlaceFilters(ownerScopes: ["you"]))
    }

    func visiblePlaces(filters: PlaceFilters = PlaceFilters()) -> [VisiblePlace] {
        mergeVisiblePlaces(localVisiblePlaces(filters: filters) + remoteVisiblePlaces(filters: filters))
    }

    private func localVisiblePlaces(filters: PlaceFilters = PlaceFilters()) -> [VisiblePlace] {
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

    private func remoteVisiblePlaces(filters: PlaceFilters) -> [VisiblePlace] {
        remoteVisiblePlaceCache.filter { visiblePlace in
            guard filters.statuses.isEmpty || filters.statuses.contains(visiblePlace.userPlace.status) else { return false }
            guard filters.categories.isEmpty || filters.categories.contains(visiblePlace.place.category) else { return false }

            guard !filters.ownerScopes.isEmpty else { return true }

            let isMine = visiblePlace.owner.id == currentUser.id
            let relationship = relationship(to: visiblePlace.owner.id)
            let isFriend = relationship == .mutual
            let isFollowing = relationship == .follower || relationship == .mutual
            return (filters.ownerScopes.contains("you") && isMine)
                || (filters.ownerScopes.contains("friends") && isFriend)
                || (filters.ownerScopes.contains("following") && isFollowing && !isMine)
                || (filters.ownerScopes.contains("social") && !isMine)
        }
    }

    private func mergeVisiblePlaces(_ places: [VisiblePlace]) -> [VisiblePlace] {
        var seen = Set<String>()
        var merged: [VisiblePlace] = []

        for visiblePlace in places where !seen.contains(visiblePlace.id) {
            seen.insert(visiblePlace.id)
            merged.append(visiblePlace)
        }

        return merged
    }

    func visiblePlaces(for profileID: String) -> [VisiblePlace] {
        visiblePlaces().filter { $0.owner.id == profileID }
    }

    func attributes(for userPlaceID: String) -> [LocalPlaceAttribute] {
        let userPlaceIDs = matchingUserPlaceIDs(userPlaceID)
        return placeAttributes
            .filter { userPlaceIDs.contains($0.userPlaceID) }
            .sorted { $0.questionKey < $1.questionKey }
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

    func discover(query: String, scope: DiscoverPlaceScope = .everyone, backend: WanderBackend? = nil) async -> DiscoverResults {
        let filters = await parseDiscover(query: query)
        var placeFilters = PlaceFilters()
        placeFilters.statuses = filters.statuses
        placeFilters.categories = filters.categories
        placeFilters.ownerScopes = scope.ownerScopes

        if scope == .everyone, let relationship = filters.relationship {
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
        }

        let places = visiblePlaces(filters: placeFilters)
        var profiles = searchProfiles(handleQuery: query)
        let normalizedProfileQuery = normalizedHandleQuery(query)

        if normalizedProfileQuery.count >= 2, let backend {
            do {
                let remoteProfiles = try await backend.searchProfiles(handleQuery: normalizedProfileQuery)
                upsertRemoteProfileShells(remoteProfiles)
                profiles = mergeProfileShells(profiles + remoteProfiles)
                lastRemoteError = nil
            } catch {
                lastRemoteError = remoteErrorMessage(error)
            }
        }

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
        sourceType: AddSourceType,
        attributes: [PlaceAttributeDraft]? = nil
    ) -> SaveResult {
        let place = upsertPlace(from: candidate, sourceType: sourceType)

        if let existing = userPlaces.first(where: { $0.userID == currentUser.id && $0.placeID == place.id && $0.deletedAt == nil }) {
            existing.statusRaw = status.rawValue
            existing.visibilityRaw = visibility.rawValue
            existing.note = note
            if let attributes {
                existing.ratingSignal = ratingSignal(from: attributes)
                replaceAttributes(for: existing.id, with: attributes, syncState: .pendingUpdate)
            }
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
            ratingSignal: attributes.flatMap { ratingSignal(from: $0) },
            nearbyConfirmed: sourceType == .currentLocation,
            sourceType: sourceType.rawValue,
            syncState: .pendingCreate
        )
        userPlaces.append(userPlace)
        if let attributes {
            replaceAttributes(for: userPlace.id, with: attributes, syncState: .pendingCreate)
        }
        return SaveResult(userPlaceID: userPlace.id, syncState: userPlace.syncState)
    }

    @discardableResult
    func saveCandidate(
        _ candidate: PlaceCandidate,
        status: PlaceStatus,
        visibility: PlaceVisibility,
        note: String?,
        sourceType: AddSourceType,
        attributes: [PlaceAttributeDraft]? = nil,
        backend: WanderBackend?
    ) async -> SaveResult {
        let localResult = saveCandidate(
            candidate,
            status: status,
            visibility: visibility,
            note: note,
            sourceType: sourceType,
            attributes: attributes
        )

        guard let backend else {
            return localResult
        }

        guard let draft = userPlaceDraft(for: localResult.userPlaceID) else {
            return localResult
        }

        do {
            let remoteResult = try await backend.saveUserPlace(draft)
            if let placeID = remoteResult.placeID {
                markPlace(localOrServerID: draft.place.localID, serverID: placeID, syncState: .synced)
            }
            markUserPlace(localOrServerID: localResult.userPlaceID, serverID: remoteResult.userPlaceID, syncState: .synced)
            lastRemoteError = nil
            return remoteResult
        } catch {
            let message = remoteErrorMessage(error)
            markUserPlace(localOrServerID: localResult.userPlaceID, syncState: .failed, error: message)
            lastRemoteError = message
            return SaveResult(userPlaceID: localResult.userPlaceID, syncState: .failed)
        }
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
        let copiedAttributes = attributes(for: visiblePlace.userPlace.id).map { attribute in
            PlaceAttributeDraft(questionKey: attribute.questionKey, valueType: attribute.valueType, valueJSON: attribute.valueJSON)
        }

        return saveCandidate(
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
            sourceType: .socialSave,
            attributes: copiedAttributes
        )
    }

    @discardableResult
    func saveVisiblePlace(_ visiblePlace: VisiblePlace, status: PlaceStatus = .wannaGo, backend: WanderBackend?) async -> SaveResult {
        let localResult = saveVisiblePlace(visiblePlace, status: status)

        guard let backend else {
            return localResult
        }
        guard let remoteIDs = remoteSocialSaveIDs(for: visiblePlace) else {
            return localResult
        }

        do {
            let remoteResult = try await backend.saveVisiblePlace(
                placeID: remoteIDs.placeID,
                sourceUserPlaceID: remoteIDs.sourceUserPlaceID
            )
            markUserPlace(localOrServerID: localResult.userPlaceID, serverID: remoteResult.userPlaceID, syncState: .synced)
            lastRemoteError = nil
            return remoteResult
        } catch {
            let message = remoteErrorMessage(error)
            markUserPlace(localOrServerID: localResult.userPlaceID, syncState: .failed, error: message)
            lastRemoteError = message
            return SaveResult(userPlaceID: localResult.userPlaceID, syncState: .failed)
        }
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

    func follow(userID: String, source: FollowSource = .profile, backend: WanderBackend?) async {
        let follow = upsertFollow(userID: userID, source: source)

        guard let follow, let backend else {
            return
        }

        do {
            try await backend.follow(userID: userID)
            follow.syncStateRaw = SyncState.synced.rawValue
            follow.lastSyncError = nil
            follow.serverUpdatedAt = .now
            lastRemoteError = nil
            objectWillChange.send()
        } catch {
            follow.syncStateRaw = SyncState.failed.rawValue
            follow.lastSyncError = remoteErrorMessage(error)
            lastRemoteError = follow.lastSyncError
            objectWillChange.send()
        }
    }

    func unfollow(userID: String) {
        follows.removeAll { $0.followerUserID == currentUser.id && $0.followedUserID == userID }
    }

    func unfollow(userID: String, backend: WanderBackend?) async {
        guard let follow = follows.first(where: { $0.followerUserID == currentUser.id && $0.followedUserID == userID }) else {
            return
        }

        guard let backend else {
            unfollow(userID: userID)
            return
        }

        follow.syncStateRaw = SyncState.pendingDelete.rawValue
        follow.lastSyncError = nil
        objectWillChange.send()

        do {
            try await backend.unfollow(userID: userID)
            lastRemoteError = nil
            unfollow(userID: userID)
        } catch {
            follow.syncStateRaw = SyncState.failed.rawValue
            follow.lastSyncError = remoteErrorMessage(error)
            lastRemoteError = follow.lastSyncError
            objectWillChange.send()
        }
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

    func block(userID: String, backend: WanderBackend?) async {
        let block = upsertBlock(userID: userID)

        guard let block, let backend else {
            return
        }

        do {
            try await backend.block(userID: userID)
            block.syncStateRaw = SyncState.synced.rawValue
            block.lastSyncError = nil
            block.serverUpdatedAt = .now
            lastRemoteError = nil
            objectWillChange.send()
        } catch {
            block.syncStateRaw = SyncState.failed.rawValue
            block.lastSyncError = remoteErrorMessage(error)
            lastRemoteError = block.lastSyncError
            objectWillChange.send()
        }
    }

    func unblock(userID: String) {
        blocks.removeAll { $0.blockerUserID == currentUser.id && $0.blockedUserID == userID }
    }

    func unblock(userID: String, backend: WanderBackend?) async {
        guard let block = blocks.first(where: { $0.blockerUserID == currentUser.id && $0.blockedUserID == userID }) else {
            return
        }

        guard let backend else {
            unblock(userID: userID)
            return
        }

        block.syncStateRaw = SyncState.pendingDelete.rawValue
        block.lastSyncError = nil
        objectWillChange.send()

        do {
            try await backend.unblock(userID: userID)
            lastRemoteError = nil
            unblock(userID: userID)
        } catch {
            block.syncStateRaw = SyncState.failed.rawValue
            block.lastSyncError = remoteErrorMessage(error)
            lastRemoteError = block.lastSyncError
            objectWillChange.send()
        }
    }

    func refreshRemoteVisiblePlaces(in viewport: MapViewport, backend: WanderBackend?) async {
        guard let backend else {
            return
        }

        do {
            remoteVisiblePlaceCache = try await backend.visiblePlaces(in: viewport)
            lastRemoteError = nil
        } catch {
            lastRemoteError = remoteErrorMessage(error)
        }
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

    private func apply(session: AuthSession) {
        let handle = normalizedSessionHandle(from: session)
        let displayName = normalizedSessionDisplayName(from: session, fallbackHandle: handle)
        let localID = "local_profile_current"
        let profile = LocalProfile(
            localID: localID,
            serverID: session.userID,
            handle: handle,
            displayName: displayName,
            syncState: .synced
        )

        currentUser = profile
        profiles.removeAll { $0.localID == localID || $0.serverID == session.userID }
        profiles.insert(profile, at: 0)
        defaultVisibility = profile.defaultVisibility
    }

    private func applySignedOutProfile() {
        let localID = "local_profile_current"
        let profile = LocalProfile(
            localID: localID,
            handle: "you",
            displayName: "You",
            syncState: .localOnly
        )

        currentUser = profile
        profiles.removeAll { $0.localID == localID }
        profiles.insert(profile, at: 0)
        defaultVisibility = profile.defaultVisibility
    }

    private func normalizedSessionHandle(from session: AuthSession) -> String {
        if let handle = session.handle.map(slug), !handle.isEmpty {
            return handle
        }

        if let emailLocalPart = session.email?.split(separator: "@").first.map(String.init),
           !slug(emailLocalPart).isEmpty {
            return slug(emailLocalPart)
        }

        let fallback = slug(session.userID)
        return fallback.isEmpty ? "you" : fallback
    }

    private func normalizedSessionDisplayName(from session: AuthSession, fallbackHandle: String) -> String {
        if let displayName = session.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !displayName.isEmpty {
            return displayName
        }

        if let email = session.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
            return email
        }

        return fallbackHandle
    }

    private func upsertFollow(userID: String, source: FollowSource) -> LocalFollow? {
        guard userID != currentUser.id,
              !isBlockedBetweenCurrentUser(and: userID)
        else { return nil }

        if let existing = follows.first(where: { $0.followerUserID == currentUser.id && $0.followedUserID == userID }) {
            return existing
        }

        let follow = LocalFollow(
            localID: "local_follow_\(currentUser.id)_\(userID)",
            followerUserID: currentUser.id,
            followedUserID: userID,
            source: source,
            syncState: .pendingCreate
        )
        follows.append(follow)
        return follow
    }

    private func upsertBlock(userID: String) -> LocalBlock? {
        guard userID != currentUser.id else { return nil }

        follows.removeAll { follow in
            (follow.followerUserID == currentUser.id && follow.followedUserID == userID)
                || (follow.followerUserID == userID && follow.followedUserID == currentUser.id)
        }

        if let existing = blocks.first(where: { $0.blockerUserID == currentUser.id && $0.blockedUserID == userID }) {
            return existing
        }

        let block = LocalBlock(
            localID: "local_block_\(currentUser.id)_\(userID)",
            blockerUserID: currentUser.id,
            blockedUserID: userID,
            syncState: .pendingCreate
        )
        blocks.append(block)
        return block
    }

    private func userPlaceDraft(for userPlaceID: String) -> UserPlaceDraft? {
        guard let userPlace = userPlaces.first(where: { $0.id == userPlaceID || $0.localID == userPlaceID || $0.serverID == userPlaceID }),
              let place = places.first(where: { $0.id == userPlace.placeID || $0.localID == userPlace.placeID || $0.serverID == userPlace.placeID })
        else {
            return nil
        }

        let placeDraft = PlaceDraft(
            localID: place.localID,
            serverID: place.serverID,
            canonicalName: place.canonicalName,
            category: place.category,
            address: place.address,
            locality: place.locality,
            region: place.region,
            country: place.country,
            latitude: place.latitude,
            longitude: place.longitude,
            sourceProvider: place.sourceProvider,
            sourceProviderPlaceID: place.sourceProviderPlaceID,
            confidence: place.confidence
        )

        let attributeDrafts = attributes(for: userPlace.id).map { attribute in
            PlaceAttributeDraft(
                questionKey: attribute.questionKey,
                valueType: attribute.valueType,
                valueJSON: attribute.valueJSON
            )
        }

        return UserPlaceDraft(
            place: placeDraft,
            status: userPlace.status,
            visibility: userPlace.visibility,
            note: userPlace.note,
            ratingSignal: userPlace.ratingSignal,
            nearbyConfirmed: userPlace.nearbyConfirmed,
            sourceType: userPlace.sourceType,
            attributes: attributeDrafts
        )
    }

    private func matchingUserPlaceIDs(_ userPlaceID: String) -> Set<String> {
        guard let userPlace = userPlaces.first(where: { $0.id == userPlaceID || $0.localID == userPlaceID || $0.serverID == userPlaceID }) else {
            return [userPlaceID]
        }

        var ids: Set<String> = [userPlaceID, userPlace.id, userPlace.localID]
        if let serverID = userPlace.serverID {
            ids.insert(serverID)
        }
        return ids
    }

    private func matchingPlaceIDs(_ placeID: String) -> Set<String> {
        guard let place = places.first(where: { $0.id == placeID || $0.localID == placeID || $0.serverID == placeID }) else {
            return [placeID]
        }

        var ids: Set<String> = [placeID, place.id, place.localID]
        if let serverID = place.serverID {
            ids.insert(serverID)
        }
        return ids
    }

    private func markUserPlace(localOrServerID: String, serverID: String? = nil, syncState: SyncState, error: String? = nil) {
        guard let userPlace = userPlaces.first(where: { $0.id == localOrServerID || $0.localID == localOrServerID || $0.serverID == localOrServerID }) else {
            return
        }

        let previousIDs = matchingUserPlaceIDs(localOrServerID)
        if let serverID {
            userPlace.serverID = serverID
        }
        userPlace.syncStateRaw = syncState.rawValue
        userPlace.lastSyncError = error
        userPlace.serverUpdatedAt = syncState == .synced ? .now : userPlace.serverUpdatedAt

        let canonicalUserPlaceID = serverID ?? userPlace.id
        for attribute in placeAttributes where previousIDs.contains(attribute.userPlaceID) {
            attribute.userPlaceID = canonicalUserPlaceID
            attribute.syncStateRaw = syncState.rawValue
            attribute.lastSyncError = error
            attribute.serverUpdatedAt = syncState == .synced ? .now : attribute.serverUpdatedAt
        }
        objectWillChange.send()
    }

    private func markPlace(localOrServerID: String, serverID: String, syncState: SyncState, error: String? = nil) {
        guard let place = places.first(where: { $0.id == localOrServerID || $0.localID == localOrServerID || $0.serverID == localOrServerID }) else {
            return
        }

        let previousIDs = matchingPlaceIDs(localOrServerID)
        place.serverID = serverID
        place.syncStateRaw = syncState.rawValue
        place.lastSyncError = error
        place.serverUpdatedAt = syncState == .synced ? .now : place.serverUpdatedAt

        for userPlace in userPlaces where previousIDs.contains(userPlace.placeID) {
            userPlace.placeID = serverID
        }
    }

    private func remoteSocialSaveIDs(for visiblePlace: VisiblePlace) -> (placeID: String, sourceUserPlaceID: String)? {
        guard let placeID = visiblePlace.place.serverID,
              let sourceUserPlaceID = visiblePlace.userPlace.serverID,
              UUID(uuidString: placeID) != nil,
              UUID(uuidString: sourceUserPlaceID) != nil
        else {
            return nil
        }

        return (placeID, sourceUserPlaceID)
    }

    private func upsertRemoteProfileShells(_ shells: [ProfileShell]) {
        for shell in shells where shell.id != currentUser.id && !isBlockedBetweenCurrentUser(and: shell.id) {
            if let existing = profiles.first(where: { $0.id == shell.id || $0.handle == shell.handle }) {
                existing.serverID = shell.id
                existing.handle = shell.handle
                existing.searchHandle = shell.handle.lowercased()
                existing.displayName = shell.displayName
                existing.avatarURL = shell.avatarURL
                existing.bio = shell.bio
                existing.syncStateRaw = SyncState.synced.rawValue
                existing.updatedAt = .now
            } else {
                profiles.append(
                    LocalProfile(
                        localID: "remote_profile_\(shell.id)",
                        serverID: shell.id,
                        handle: shell.handle,
                        displayName: shell.displayName,
                        avatarURL: shell.avatarURL,
                        bio: shell.bio,
                        syncState: .synced
                    )
                )
            }
        }
        objectWillChange.send()
    }

    private func mergeProfileShells(_ shells: [ProfileShell]) -> [ProfileShell] {
        var seen = Set<String>()
        var merged: [ProfileShell] = []

        for shell in shells where shell.id != currentUser.id && !isBlockedBetweenCurrentUser(and: shell.id) && !seen.contains(shell.id) {
            seen.insert(shell.id)
            merged.append(shell)
        }

        return merged
    }

    private func normalizedHandleQuery(_ query: String) -> String {
        query
            .lowercased()
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func remoteErrorMessage(_ error: Error) -> String {
        String(describing: error)
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

    private func replaceAttributes(for userPlaceID: String, with drafts: [PlaceAttributeDraft], syncState: SyncState) {
        placeAttributes.removeAll { $0.userPlaceID == userPlaceID }

        let uniqueDrafts = Dictionary(grouping: drafts, by: \.questionKey)
            .compactMap { $0.value.last }
            .sorted { $0.questionKey < $1.questionKey }

        for draft in uniqueDrafts where draft.valueJSON != "null" {
            placeAttributes.append(
                LocalPlaceAttribute(
                    localID: "local_attr_\(slug(userPlaceID))_\(slug(draft.questionKey))",
                    userPlaceID: userPlaceID,
                    questionKey: draft.questionKey,
                    valueType: draft.valueType,
                    valueJSON: draft.valueJSON,
                    syncState: syncState
                )
            )
        }
    }

    private func ratingSignal(from attributes: [PlaceAttributeDraft]) -> String? {
        guard let rating = attributes.first(where: { $0.questionKey == "rating_signal" }),
              let data = rating.valueJSON.data(using: .utf8)
        else { return nil }

        return try? JSONDecoder().decode(String.self, from: data)
    }

    private func slug(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }
}
