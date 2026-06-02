import XCTest
@testable import Wander

@MainActor
final class AuthSessionTests: XCTestCase {
    func testRequireSignInRunsActionWhenSignedIn() {
        let provider = PreviewAuthSessionProvider(
            state: .signedIn(AuthSession(userID: "user_123", displayName: "Joe", handle: "joe")),
            token: "token"
        )
        let store = AuthSessionStore(provider: provider)
        var actionRan = false

        store.requireSignIn(for: .followPeople) {
            actionRan = true
        }

        XCTAssertTrue(actionRan)
        XCTAssertNil(store.activeGate)
    }

    func testRequireSignInPresentsGateWhenSignedOut() {
        let store = AuthSessionStore(provider: PreviewAuthSessionProvider(state: .signedOut))
        var actionRan = false

        store.requireSignIn(for: .socialSave) {
            actionRan = true
        }

        XCTAssertFalse(actionRan)
        XCTAssertEqual(store.activeGate?.intent, .socialSave)
    }

    func testSupabaseTokenRequiresSignedInSession() async {
        let signedOutProvider = PreviewAuthSessionProvider(state: .signedOut, token: "token")
        let signedOutStore = AuthSessionStore(provider: signedOutProvider)

        do {
            _ = try await signedOutStore.supabaseAccessToken()
            XCTFail("Expected signed-out token lookup to throw")
        } catch let error as AuthSessionError {
            XCTAssertEqual(error, .notSignedIn)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let signedInProvider = PreviewAuthSessionProvider(
            state: .signedIn(AuthSession(userID: "user_123", displayName: nil, handle: nil)),
            token: "token"
        )
        let signedInStore = AuthSessionStore(provider: signedInProvider)

        let token = try? await signedInStore.supabaseAccessToken()

        XCTAssertEqual(token, "token")
    }
}
