import Foundation

struct AnalyticsEvent: Equatable {
    let name: String
    var properties: [String: String] = [:]
}

struct NoopAnalyticsClient: AnalyticsClient {
    func track(_ event: AnalyticsEvent) {}
}

enum WanderAnalyticsEvents {
    static let onboardingStarted = "onboarding_started"
    static let locationPermissionResult = "location_permission_result"
    static let firstPlaceStarted = "first_place_started"
    static let placeCandidateShown = "place_candidate_shown"
    static let placeSaved = "place_saved"
    static let visibilityChanged = "visibility_changed"
    static let followCreated = "follow_created"
    static let followRemoved = "follow_removed"
    static let blockCreated = "block_created"
    static let discoverFilterUsed = "discover_filter_used"
    static let discoverQueryParsed = "discover_query_parsed"
    static let discoverParseFailed = "discover_parse_failed"
    static let socialPlaceSaved = "social_place_saved"
    static let syncFailed = "sync_failed"
    static let extractionJobStarted = "extraction_job_started"
    static let extractionJobCompleted = "extraction_job_completed"
    static let extractionJobFailed = "extraction_job_failed"
}
