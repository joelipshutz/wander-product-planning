import SwiftData
import SwiftUI

@main
struct WanderApp: App {
    var body: some Scene {
        WindowGroup {
            WanderRootView()
        }
        .modelContainer(WanderModelContainer.preview)
    }
}
