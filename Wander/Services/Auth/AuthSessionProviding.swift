import Foundation

enum AuthState: Equatable {
    case signedOut
    case loading
    case signedIn(AuthSession)
    case unavailable(String)

    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }
}

struct AuthSession: Equatable, Identifiable {
    let userID: String
    let displayName: String?
    let handle: String?

    var id: String { userID }
}

enum AuthGateIntent: String, Equatable, Identifiable {
    case syncPlace
    case socialSave
    case followPeople
    case manageBlocks
    case syncPending

    var id: String { rawValue }

    var copy: AuthGateCopy {
        switch self {
        case .syncPlace:
            AuthGateCopy(
                title: "Sign in to sync this place",
                message: "It stays on this phone either way. Sign in when you want it backed up and shared by your visibility setting.",
                primaryAction: "Sign in",
                secondaryAction: "Keep it here"
            )
        case .socialSave:
            AuthGateCopy(
                title: "Sign in to save from people",
                message: "Social saves need an account so Wander knows whose map gets the copy.",
                primaryAction: "Sign in",
                secondaryAction: "Keep browsing"
            )
        case .followPeople:
            AuthGateCopy(
                title: "Sign in to follow people",
                message: "Follows shape your social map and need an account.",
                primaryAction: "Sign in",
                secondaryAction: "Not now"
            )
        case .manageBlocks:
            AuthGateCopy(
                title: "Sign in to manage blocks",
                message: "Blocks apply across search, profiles, and maps, so they need an account.",
                primaryAction: "Sign in",
                secondaryAction: "Cancel"
            )
        case .syncPending:
            AuthGateCopy(
                title: "Sign in to sync pending items",
                message: "Your local saves are safe here. Sign in to back them up when you're ready.",
                primaryAction: "Sign in",
                secondaryAction: "Later"
            )
        }
    }
}

struct AuthGateRequest: Equatable, Identifiable {
    let intent: AuthGateIntent
    let createdAt: Date

    var id: String { "\(intent.rawValue)-\(createdAt.timeIntervalSince1970)" }
    var copy: AuthGateCopy { intent.copy }
}

enum AuthSessionError: Error, Equatable {
    case notSignedIn
    case notConfigured
    case tokenUnavailable
}

@MainActor
protocol AuthSessionProviding: AnyObject {
    var state: AuthState { get }
    var canPresentNativeAuth: Bool { get }
    func refreshSession() async
    func supabaseAccessToken() async throws -> String
}

@MainActor
final class AuthSessionStore: ObservableObject, AuthSessionProviding {
    @Published private(set) var state: AuthState
    @Published var activeGate: AuthGateRequest?
    @Published var isPresentingNativeAuth = false

    private let provider: AuthSessionProviding

    init(provider: AuthSessionProviding) {
        self.provider = provider
        self.state = provider.state
    }

    var isSignedIn: Bool {
        state.isSignedIn
    }

    var canPresentNativeAuth: Bool {
        provider.canPresentNativeAuth
    }

    func refreshSession() async {
        await provider.refreshSession()
        state = provider.state
    }

    func requireSignIn(for intent: AuthGateIntent, action: () -> Void) {
        if isSignedIn {
            action()
        } else {
            presentGate(for: intent)
        }
    }

    func presentGate(for intent: AuthGateIntent) {
        activeGate = AuthGateRequest(intent: intent, createdAt: .now)
    }

    func dismissGate() {
        activeGate = nil
    }

    func beginSignIn() {
        activeGate = nil
        if provider.canPresentNativeAuth {
            isPresentingNativeAuth = true
        } else {
            state = .unavailable("Clerk is not configured for this build.")
        }
    }

    func supabaseAccessToken() async throws -> String {
        try await provider.supabaseAccessToken()
    }
}

@MainActor
final class PreviewAuthSessionProvider: AuthSessionProviding {
    private(set) var state: AuthState
    let canPresentNativeAuth: Bool
    private let token: String?

    init(state: AuthState = .signedOut, canPresentNativeAuth: Bool = false, token: String? = nil) {
        self.state = state
        self.canPresentNativeAuth = canPresentNativeAuth
        self.token = token
    }

    func setState(_ state: AuthState) {
        self.state = state
    }

    func refreshSession() async {}

    func supabaseAccessToken() async throws -> String {
        guard state.isSignedIn else { throw AuthSessionError.notSignedIn }
        guard let token else { throw AuthSessionError.tokenUnavailable }
        return token
    }
}
