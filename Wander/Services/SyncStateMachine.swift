import Foundation

struct SyncStateMachine {
    func canTransition(from current: SyncState, to next: SyncState) -> Bool {
        allowedTransitions[current, default: []].contains(next)
    }

    private var allowedTransitions: [SyncState: Set<SyncState>] {
        [
            .localOnly: [.pendingCreate, .tombstoned],
            .pendingCreate: [.synced, .failed, .serverDenied, .tombstoned],
            .pendingUpdate: [.synced, .failed, .serverDenied, .tombstoned],
            .pendingDelete: [.tombstoned, .failed],
            .failed: [.pendingCreate, .pendingUpdate, .pendingDelete, .tombstoned],
            .synced: [.pendingUpdate, .pendingDelete, .tombstoned],
            .serverDenied: [.localOnly, .tombstoned],
            .tombstoned: []
        ]
    }
}
