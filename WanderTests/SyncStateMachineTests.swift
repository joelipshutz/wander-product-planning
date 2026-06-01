import XCTest
@testable import Wander

final class SyncStateMachineTests: XCTestCase {
    private let stateMachine = SyncStateMachine()

    func testAllowedCreateFlowTransitions() {
        XCTAssertTrue(stateMachine.canTransition(from: .localOnly, to: .pendingCreate))
        XCTAssertTrue(stateMachine.canTransition(from: .pendingCreate, to: .synced))
        XCTAssertTrue(stateMachine.canTransition(from: .pendingCreate, to: .failed))
        XCTAssertTrue(stateMachine.canTransition(from: .pendingCreate, to: .serverDenied))
    }

    func testServerDeniedCanOnlyBecomeLocalOnlyOrTombstoned() {
        XCTAssertTrue(stateMachine.canTransition(from: .serverDenied, to: .localOnly))
        XCTAssertTrue(stateMachine.canTransition(from: .serverDenied, to: .tombstoned))
        XCTAssertFalse(stateMachine.canTransition(from: .serverDenied, to: .synced))
    }

    func testTombstonedIsTerminal() {
        for state in SyncState.allCases where state != .tombstoned {
            XCTAssertFalse(stateMachine.canTransition(from: .tombstoned, to: state))
        }
    }
}
