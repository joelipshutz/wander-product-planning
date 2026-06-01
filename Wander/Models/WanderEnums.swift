import Foundation

enum PlaceVisibility: String, Codable, CaseIterable, Equatable {
    case followers
    case mutuals
    case selfOnly = "self"
}

enum PlaceStatus: String, Codable, CaseIterable, Equatable {
    case been
    case wannaGo = "wanna_go"
}

enum SyncState: String, Codable, CaseIterable, Equatable {
    case localOnly = "local_only"
    case pendingCreate = "pending_create"
    case pendingUpdate = "pending_update"
    case pendingDelete = "pending_delete"
    case synced
    case failed
    case serverDenied = "server_denied"
    case tombstoned
}

enum FollowSource: String, Codable, CaseIterable, Equatable {
    case username
    case contacts
    case profile
    case inviteLinkFuture = "invite_link_future"
}

enum ExtractionStatus: String, Codable, CaseIterable, Equatable {
    case pending
    case running
    case needsConfirmation = "needs_confirmation"
    case complete
    case failed
    case noPlaceFound = "no_place_found"
}

enum ViewerRelationship: String, Codable, Equatable {
    case owner
    case mutual
    case follower
    case nonFollower = "non_follower"
}
