import Foundation
import SwiftData

@Model
final class LocalProfile {
    @Attribute(.unique) var id: String
    var displayName: String
    var handle: String
    var avatarURL: String?
    var bio: String?
    var homeArea: String?
    var defaultVisibilityRaw: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        displayName: String,
        handle: String,
        avatarURL: String? = nil,
        bio: String? = nil,
        homeArea: String? = nil,
        defaultVisibility: PlaceVisibility = .followers,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.handle = handle
        self.avatarURL = avatarURL
        self.bio = bio
        self.homeArea = homeArea
        self.defaultVisibilityRaw = defaultVisibility.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var defaultVisibility: PlaceVisibility {
        PlaceVisibility(rawValue: defaultVisibilityRaw) ?? .followers
    }
}

@Model
final class LocalFollow {
    @Attribute(.unique) var id: String
    var followerUserID: String
    var followedUserID: String
    var sourceRaw: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        followerUserID: String,
        followedUserID: String,
        source: FollowSource,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.followerUserID = followerUserID
        self.followedUserID = followedUserID
        self.sourceRaw = source.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class LocalBlock {
    @Attribute(.unique) var id: String
    var blockerUserID: String
    var blockedUserID: String
    var createdAt: Date

    init(id: String, blockerUserID: String, blockedUserID: String, createdAt: Date = .now) {
        self.id = id
        self.blockerUserID = blockerUserID
        self.blockedUserID = blockedUserID
        self.createdAt = createdAt
    }
}

@Model
final class LocalPlace {
    @Attribute(.unique) var id: String
    var canonicalName: String
    var category: String
    var latitude: Double
    var longitude: Double
    var provider: String?
    var providerID: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        canonicalName: String,
        category: String,
        latitude: Double,
        longitude: Double,
        provider: String? = nil,
        providerID: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.canonicalName = canonicalName
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.provider = provider
        self.providerID = providerID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class LocalUserPlace {
    @Attribute(.unique) var id: String
    var userID: String
    var placeID: String
    var statusRaw: String
    var note: String?
    var visibilityRaw: String
    var nearbyConfirmed: Bool
    var visitedAt: Date?
    var savedAt: Date
    var sourceType: String
    var sourceArtifactID: String?
    var syncStateRaw: String
    var localUpdatedAt: Date
    var serverUpdatedAt: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        userID: String,
        placeID: String,
        status: PlaceStatus,
        visibility: PlaceVisibility,
        note: String? = nil,
        nearbyConfirmed: Bool = false,
        visitedAt: Date? = nil,
        savedAt: Date = .now,
        sourceType: String,
        sourceArtifactID: String? = nil,
        syncState: SyncState = .localOnly,
        localUpdatedAt: Date = .now,
        serverUpdatedAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.userID = userID
        self.placeID = placeID
        self.statusRaw = status.rawValue
        self.note = note
        self.visibilityRaw = visibility.rawValue
        self.nearbyConfirmed = nearbyConfirmed
        self.visitedAt = visitedAt
        self.savedAt = savedAt
        self.sourceType = sourceType
        self.sourceArtifactID = sourceArtifactID
        self.syncStateRaw = syncState.rawValue
        self.localUpdatedAt = localUpdatedAt
        self.serverUpdatedAt = serverUpdatedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var status: PlaceStatus {
        PlaceStatus(rawValue: statusRaw) ?? .wannaGo
    }

    var visibility: PlaceVisibility {
        PlaceVisibility(rawValue: visibilityRaw) ?? .followers
    }

    var syncState: SyncState {
        SyncState(rawValue: syncStateRaw) ?? .localOnly
    }
}

@Model
final class LocalPlaceAttribute {
    @Attribute(.unique) var id: String
    var userPlaceID: String
    var questionKey: String
    var valueType: String
    var value: String
    var createdAt: Date
    var updatedAt: Date

    init(id: String, userPlaceID: String, questionKey: String, valueType: String, value: String, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.userPlaceID = userPlaceID
        self.questionKey = questionKey
        self.valueType = valueType
        self.value = value
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class LocalSourceArtifact {
    @Attribute(.unique) var id: String
    var userID: String
    var type: String
    var originalInput: String
    var normalizedInput: String
    var localAssetRef: String?
    var remoteAssetRef: String?
    var createdAt: Date
    var deletedAt: Date?

    init(id: String, userID: String, type: String, originalInput: String, normalizedInput: String, localAssetRef: String? = nil, remoteAssetRef: String? = nil, createdAt: Date = .now, deletedAt: Date? = nil) {
        self.id = id
        self.userID = userID
        self.type = type
        self.originalInput = originalInput
        self.normalizedInput = normalizedInput
        self.localAssetRef = localAssetRef
        self.remoteAssetRef = remoteAssetRef
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }
}

@Model
final class LocalExtractionJob {
    @Attribute(.unique) var id: String
    var sourceArtifactID: String
    var statusRaw: String
    var providerStepsJSON: String
    var extractedCandidatesJSON: String
    var selectedPlaceID: String?
    var confidence: Double
    var errorCode: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: String, sourceArtifactID: String, status: ExtractionStatus, providerStepsJSON: String = "[]", extractedCandidatesJSON: String = "[]", selectedPlaceID: String? = nil, confidence: Double = 0, errorCode: String? = nil, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.sourceArtifactID = sourceArtifactID
        self.statusRaw = status.rawValue
        self.providerStepsJSON = providerStepsJSON
        self.extractedCandidatesJSON = extractedCandidatesJSON
        self.selectedPlaceID = selectedPlaceID
        self.confidence = confidence
        self.errorCode = errorCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class SyncOperation {
    @Attribute(.unique) var id: String
    var entityName: String
    var entityID: String
    var operation: String
    var attemptCount: Int
    var lastError: String?
    var createdAt: Date
    var updatedAt: Date

    init(id: String, entityName: String, entityID: String, operation: String, attemptCount: Int = 0, lastError: String? = nil, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.entityName = entityName
        self.entityID = entityID
        self.operation = operation
        self.attemptCount = attemptCount
        self.lastError = lastError
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
