import Foundation

@MainActor
protocol ProfileRepository {
    func currentProfile() async throws -> LocalProfile?
    func searchProfiles(handleQuery: String) async throws -> [LocalProfile]
}

@MainActor
protocol FollowRepository {
    func follow(userID: String) async throws
    func unfollow(userID: String) async throws
    func relationship(to userID: String) async throws -> ViewerRelationship
}

@MainActor
protocol BlockRepository {
    func block(userID: String) async throws
    func isBlocked(userID: String) async throws -> Bool
}

@MainActor
protocol PlaceRepository {
    func placesInCurrentViewport() async throws -> [LocalPlace]
}

@MainActor
protocol UserPlaceRepository {
    func userPlaces(for userID: String) async throws -> [LocalUserPlace]
    func save(_ userPlace: LocalUserPlace) async throws
}

@MainActor
protocol SourceArtifactRepository {
    func save(_ artifact: LocalSourceArtifact) async throws
}

@MainActor
protocol ExtractionRepository {
    func job(for artifactID: String) async throws -> LocalExtractionJob?
}

@MainActor
protocol DiscoverRepository {
    func search(filters: DiscoverFilters) async throws -> [VisiblePlace]
}

@MainActor
protocol AnalyticsClient {
    func track(_ event: AnalyticsEvent)
}
