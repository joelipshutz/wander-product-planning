import XCTest
@testable import Wander

final class VisibilityPolicyTests: XCTestCase {
    private let policy = VisibilityPolicy()

    func testOwnerCanSeeAllVisibilityLevels() {
        XCTAssertTrue(policy.canSeePlace(viewerID: "u1", ownerID: "u1", visibility: .selfOnly, relationship: .owner, isBlocked: false))
        XCTAssertTrue(policy.canSeePlace(viewerID: "u1", ownerID: "u1", visibility: .mutuals, relationship: .owner, isBlocked: false))
        XCTAssertTrue(policy.canSeePlace(viewerID: "u1", ownerID: "u1", visibility: .followers, relationship: .owner, isBlocked: false))
    }

    func testFollowerCanSeeFollowersButNotMutualOrSelf() {
        XCTAssertTrue(policy.canSeePlace(viewerID: "u2", ownerID: "u1", visibility: .followers, relationship: .follower, isBlocked: false))
        XCTAssertFalse(policy.canSeePlace(viewerID: "u2", ownerID: "u1", visibility: .mutuals, relationship: .follower, isBlocked: false))
        XCTAssertFalse(policy.canSeePlace(viewerID: "u2", ownerID: "u1", visibility: .selfOnly, relationship: .follower, isBlocked: false))
    }

    func testMutualCanSeeFollowersAndMutuals() {
        XCTAssertTrue(policy.canSeePlace(viewerID: "u2", ownerID: "u1", visibility: .followers, relationship: .mutual, isBlocked: false))
        XCTAssertTrue(policy.canSeePlace(viewerID: "u2", ownerID: "u1", visibility: .mutuals, relationship: .mutual, isBlocked: false))
        XCTAssertFalse(policy.canSeePlace(viewerID: "u2", ownerID: "u1", visibility: .selfOnly, relationship: .mutual, isBlocked: false))
    }

    func testBlockOverridesAllVisibility() {
        XCTAssertFalse(policy.canSeePlace(viewerID: "u1", ownerID: "u1", visibility: .selfOnly, relationship: .owner, isBlocked: true))
        XCTAssertFalse(policy.canSeePlace(viewerID: "u2", ownerID: "u1", visibility: .followers, relationship: .mutual, isBlocked: true))
    }
}
