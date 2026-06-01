import SwiftUI

struct WanderRootView: View {
    @State private var selection: WanderTab = .map
    private let fixtures = WanderFixtures.seed

    var body: some View {
        TabView(selection: $selection) {
            MapScreen(fixtures: fixtures)
                .tabItem { Label("Map", systemImage: "map") }
                .tag(WanderTab.map)

            AddScreen(fixtures: fixtures)
                .tabItem { Label("Add", systemImage: "plus.circle.fill") }
                .tag(WanderTab.add)

            DiscoverScreen(fixtures: fixtures)
                .tabItem { Label("Discover", systemImage: "sparkle.magnifyingglass") }
                .tag(WanderTab.discover)

            ProfileScreen(fixtures: fixtures)
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(WanderTab.profile)
        }
        .tint(WanderTheme.terracotta)
    }
}

enum WanderTab: Hashable {
    case map
    case add
    case discover
    case profile
}
