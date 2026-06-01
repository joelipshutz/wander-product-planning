import Foundation

struct VisibilityPolicy {
    func canSeePlace(
        viewerID: String?,
        ownerID: String,
        visibility: PlaceVisibility,
        relationship: ViewerRelationship,
        isBlocked: Bool
    ) -> Bool {
        guard !isBlocked else { return false }
        guard let viewerID else { return false }
        guard viewerID != ownerID else { return true }

        switch visibility {
        case .selfOnly:
            return false
        case .followers:
            return relationship == .follower || relationship == .mutual
        case .mutuals:
            return relationship == .mutual
        }
    }
}
