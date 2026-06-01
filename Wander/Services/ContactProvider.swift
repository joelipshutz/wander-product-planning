import Foundation

struct ContactMatch: Identifiable, Equatable {
    let id: String
    let displayName: String
    let handle: String?
    let userID: String?
}

protocol ContactProvider {
    func matches() async throws -> [ContactMatch]
}

struct FakeContactProvider: ContactProvider {
    let seededMatches: [ContactMatch]

    func matches() async throws -> [ContactMatch] {
        seededMatches
    }
}
