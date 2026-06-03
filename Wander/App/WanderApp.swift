import SwiftUI
import SwiftData

@main
struct WanderApp: App {
    @StateObject private var auth: AuthSessionStore
    @StateObject private var backend: WanderBackend

    init() {
        let configuration = WanderBackendConfiguration.current()
        let authStore = AuthSessionStore(provider: ClerkAuthService(configuration: configuration))
        _auth = StateObject(wrappedValue: authStore)
        _backend = StateObject(wrappedValue: WanderBackend(configuration: configuration, authSession: authStore))
    }

    var body: some Scene {
        WindowGroup {
            WanderRootView()
                .environmentObject(auth)
                .environmentObject(backend)
                .modelContainer(WanderModelContainer.preview)
        }
    }
}
