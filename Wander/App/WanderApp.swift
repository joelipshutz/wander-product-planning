import SwiftUI
import SwiftData

@main
struct WanderApp: App {
    var body: some Scene {
        WindowGroup {
            WanderRootView()
                .modelContainer(WanderModelContainer.preview)
        }
    }
}
