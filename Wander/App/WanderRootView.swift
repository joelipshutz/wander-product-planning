import SwiftUI

struct WanderRootView: View {
    @State private var selection: WanderTab = .map
    @StateObject private var store = InMemoryWanderStore()

    var body: some View {
        TabView(selection: $selection) {
            MapScreen()
                .tabItem { Label("Map", systemImage: "map") }
                .tag(WanderTab.map)

            AddScreen()
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(WanderTab.add)

            DiscoverScreen()
                .tabItem { Label("Discover", systemImage: "sparkle.magnifyingglass") }
                .tag(WanderTab.discover)

            ProfileScreen()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(WanderTab.profile)

            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(WanderTab.settings)
        }
        .tint(WanderTheme.terracotta)
        .environmentObject(store)
    }
}

enum WanderTab: Hashable {
    case map
    case add
    case discover
    case profile
    case settings
}
