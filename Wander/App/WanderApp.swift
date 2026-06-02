import SwiftUI
import SwiftData

@main
struct WanderApp: App {
    @StateObject private var auth: AuthSessionStore

    init() {
        let configuration = WanderBackendConfiguration.current()
        _auth = StateObject(wrappedValue: AuthSessionStore(provider: ClerkAuthService(configuration: configuration)))
    }

    var body: some Scene {
        WindowGroup {
            WanderRootView()
                .environmentObject(auth)
                .modelContainer(WanderModelContainer.preview)
        }
    }
}
