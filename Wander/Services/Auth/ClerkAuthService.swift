import Foundation
#if canImport(ClerkKit)
import ClerkKit
#endif

@MainActor
final class ClerkAuthService: AuthSessionProviding {
    private(set) var state: AuthState = .signedOut
    private let configuration: WanderBackendConfiguration

    init(configuration: WanderBackendConfiguration) {
        self.configuration = configuration

        #if canImport(ClerkKit)
        if let publishableKey = configuration.clerkPublishableKey {
            Clerk.configure(publishableKey: publishableKey)
        } else {
            state = .unavailable("Missing Clerk publishable key.")
        }
        #else
        state = .unavailable("ClerkKit is not linked.")
        #endif
    }

    var canPresentNativeAuth: Bool {
        configuration.isClerkConfigured
    }

    func refreshSession() async {
        #if canImport(ClerkKit)
        guard configuration.isClerkConfigured else {
            state = .unavailable("Missing Clerk publishable key.")
            return
        }

        if let user = Clerk.shared.user {
            let name = [user.firstName, user.lastName]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            state = .signedIn(
                AuthSession(
                    userID: user.id,
                    displayName: name.isEmpty ? user.username : name,
                    handle: user.username
                )
            )
        } else {
            state = .signedOut
        }
        #else
        state = .unavailable("ClerkKit is not linked.")
        #endif
    }

    func signOut() async throws {
        #if canImport(ClerkKit)
        guard configuration.isClerkConfigured else {
            throw AuthSessionError.notConfigured
        }
        try await Clerk.shared.auth.signOut()
        state = .signedOut
        #else
        throw AuthSessionError.notConfigured
        #endif
    }

    func supabaseAccessToken() async throws -> String {
        #if canImport(ClerkKit)
        guard configuration.isClerkConfigured else {
            throw AuthSessionError.notConfigured
        }
        guard Clerk.shared.user != nil else {
            throw AuthSessionError.notSignedIn
        }
        guard let token = try await Clerk.shared.auth.getToken() else {
            throw AuthSessionError.tokenUnavailable
        }
        return token
        #else
        throw AuthSessionError.notConfigured
        #endif
    }
}
