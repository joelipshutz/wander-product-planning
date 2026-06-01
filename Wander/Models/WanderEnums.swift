import Foundation

enum PlaceVisibility: String, Codable, CaseIterable {
    case followers
    case mutuals
    case selfOnly = "self"
}

enum PlaceStatus: String, Codable, CaseIterable {
    case been
    case wannaGo = "wanna_go"
}

enum SyncState: String, Codable, CaseIterable {
    case localOnly = "local_only"
    case pendingCreate = "pending_create"
    case pendingUpdate = "pending_update"
    case pendingDelete = "pending_delete"
    case synced
    case failed
    case tombstoned
}

enum FollowSource: String, Codable, CaseIterable {
    case username
    case contacts
    case profile
    case inviteLinkFuture = "invite_link_future"
}

enum ExtractionStatus: String, Codable, CaseIterable {
    case pending
    case running
    case needsConfirmation = "needs_confirmation"
    case complete
    case failed
    case noPlaceFound = "no_place_found"
}

enum ViewerRelationship: Equatable {
    case owner
    case follower
    case mutual
    case nonFollower
}
