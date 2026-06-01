import Foundation

struct ProfileShell: Identifiable, Equatable {
    let id: String
    let handle: String
    let displayName: String
    let avatarURL: String?
    let bio: String?
    let relationship: ViewerRelationship
}

struct ProfileViewState {
    let shell: ProfileShell
    let visiblePlaces: [VisiblePlace]
    let canFollow: Bool
    let canBlock: Bool
    let isBlocked: Bool
}

struct MapViewport: Equatable {
    let minLatitude: Double
    let minLongitude: Double
    let maxLatitude: Double
    let maxLongitude: Double
}

struct PlaceFilters: Equatable {
    var statuses: Set<PlaceStatus> = []
    var categories: Set<String> = []
    var ownerScopes: Set<String> = []
}

struct ManualPlaceInput: Equatable {
    let name: String
    let areaHint: String?
    let category: String?
}

struct PlaceCandidate: Identifiable, Equatable {
    let id: String
    let name: String
    let category: String
    let latitude: Double?
    let longitude: Double?
    let confidence: Double
}

struct UserPlaceDraft: Equatable {
    let placeID: String
    let status: PlaceStatus
    let visibility: PlaceVisibility
    let note: String?
    let sourceType: String
}

struct SaveResult: Equatable {
    let userPlaceID: String
    let syncState: SyncState
}

@MainActor
protocol ProfileRepository {
    func currentProfile() async throws -> LocalProfile?
    func profile(id: String) async throws -> ProfileViewState
    func searchProfiles(handleQuery: String) async throws -> [ProfileShell]
}

@MainActor
protocol FollowRepository {
    func follow(userID: String) async throws
    func unfollow(userID: String) async throws
    func followers(userID: String) async throws -> [ProfileShell]
    func following(userID: String) async throws -> [ProfileShell]
    func relationship(to userID: String) async throws -> ViewerRelationship
}

@MainActor
protocol BlockRepository {
    func block(userID: String) async throws
    func unblock(userID: String) async throws
    func blockedProfiles() async throws -> [ProfileShell]
    func isBlocked(userID: String) async throws -> Bool
}

@MainActor
protocol PlaceRepository {
    func places(in viewport: MapViewport) async throws -> [VisiblePlace]
    func resolveCurrentLocation() async throws -> [PlaceCandidate]
    func resolveManualEntry(_ input: ManualPlaceInput) async throws -> [PlaceCandidate]
}

@MainActor
protocol UserPlaceRepository {
    func userPlaces(for userID: String, filters: PlaceFilters) async throws -> [VisiblePlace]
    func save(_ draft: UserPlaceDraft) async throws -> SaveResult
    func updateVisibility(userPlaceID: String, visibility: PlaceVisibility) async throws
    func delete(userPlaceID: String) async throws
}

@MainActor
protocol DiscoverRepository {
    func parseFilters(query: String) async throws -> DiscoverFilters
    func search(filters: DiscoverFilters) async throws -> DiscoverResults
}
