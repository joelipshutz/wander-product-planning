import Foundation

protocol ProfileRepository {
    func currentProfile() async throws -> LocalProfile?
    func searchProfiles(handleQuery: String) async throws -> [LocalProfile]
}

protocol FollowRepository {
    func follow(userID: String) async throws
    func unfollow(userID: String) async throws
    func relationship(to userID: String) async throws -> ViewerRelationship
}

protocol BlockRepository {
    func block(userID: String) async throws
    func isBlocked(userID: String) async throws -> Bool
}

protocol PlaceRepository {
    func placesInCurrentViewport() async throws -> [LocalPlace]
}

protocol UserPlaceRepository {
    func userPlaces(for userID: String) async throws -> [LocalUserPlace]
    func save(_ userPlace: LocalUserPlace) async throws
}

protocol SourceArtifactRepository {
    func save(_ artifact: LocalSourceArtifact) async throws
}

protocol ExtractionRepository {
    func job(for artifactID: String) async throws -> LocalExtractionJob?
}

protocol DiscoverRepository {
    func search(filters: DiscoverFilters) async throws -> [VisiblePlace]
}

protocol AnalyticsClient {
    func track(_ event: AnalyticsEvent)
}
